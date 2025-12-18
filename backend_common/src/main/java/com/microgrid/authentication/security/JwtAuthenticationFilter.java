package com.microgrid.authentication.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    
    @Autowired
    private JwtTokenProvider tokenProvider;
    
    @Autowired
    private UserDetailsService userDetailsService;
    
    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getRequestURI();
        // Ignorer le filtre JWT pour les endpoints publics
        // MAIS appliquer le filtre pour /api/auth/me qui nécessite une authentification
        if (path.equals("/api/auth/me") || path.equals("/api/auth/me/")) {
            logger.info("🔐 JWT Filter WILL be applied for: " + path);
            return false; // Appliquer le filtre JWT pour /api/auth/me
        }
        // Pour /api/establishments, on applique le filtre pour traiter le token s'il est présent
        // mais on ne bloque pas la requête si le token est absent ou invalide
        if (path.startsWith("/api/establishments")) {
            logger.debug("🔍 JWT Filter WILL be applied for /api/establishments (optional auth)");
            return false; // Appliquer le filtre pour traiter le token s'il est présent
        }
        boolean shouldSkip = path.startsWith("/api/auth/") || 
               path.startsWith("/api/location/") || 
               path.startsWith("/api/public/");
        if (shouldSkip) {
            logger.debug("⏭️ JWT Filter SKIPPED for: " + path);
        }
        return shouldSkip;
    }
    
    @Override
    protected void doFilterInternal(HttpServletRequest request, 
                                    HttpServletResponse response, 
                                    FilterChain filterChain) throws ServletException, IOException {
        String path = request.getRequestURI();
        logger.info("🔍 JWT Filter processing request: " + path);
        
        try {
            String jwt = getJwtFromRequest(request);
            
            if (StringUtils.hasText(jwt)) {
                logger.info("✅ JWT token found in request (length: " + jwt.length() + ")");
                try {
                    boolean isValid = tokenProvider.validateToken(jwt);
                    logger.info("🔐 Token validation result: " + isValid);
                    
                    if (isValid) {
                        String email = tokenProvider.getEmailFromToken(jwt);
                        logger.info("📧 Extracted email from token: " + email);
                        
                        UserDetails userDetails = userDetailsService.loadUserByUsername(email);
                        UsernamePasswordAuthenticationToken authentication = 
                            new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());
                        authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                        
                        SecurityContextHolder.getContext().setAuthentication(authentication);
                        logger.info("✅ Authentication set in SecurityContext for user: " + email);
                    } else {
                        logger.warn("⚠️ Token validation failed - token is invalid or expired");
                    }
                } catch (Exception tokenEx) {
                    // Token invalide ou expiré - logger l'erreur détaillée
                    logger.error("❌ Token validation exception: " + tokenEx.getClass().getSimpleName() + " - " + tokenEx.getMessage(), tokenEx);
                }
            } else {
                logger.warn("⚠️ No JWT token found in Authorization header for path: " + path);
            }
        } catch (Exception ex) {
            // Erreur générale - logger mais ne pas bloquer
            logger.error("❌ Could not set user authentication in security context", ex);
        }
        
        filterChain.doFilter(request, response);
    }
    
    private String getJwtFromRequest(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        return null;
    }
}


