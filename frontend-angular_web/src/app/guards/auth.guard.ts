import { Injectable } from '@angular/core';
import { CanActivate, Router, ActivatedRouteSnapshot } from '@angular/router';
import { AuthService } from '../services/auth.service';

@Injectable({
  providedIn: 'root'
})
export class AuthGuard implements CanActivate {
  constructor(
    private authService: AuthService,
    private router: Router
  ) {}

  canActivate(route: ActivatedRouteSnapshot): boolean {
    // Vérifier le token standard
    const token = localStorage.getItem('auth_token');
    if (token && token.trim().length > 0) {
      return true;
    }
    
    // Vérifier aussi si l'utilisateur est connecté via le workflow mobile
    // Le workflow mobile peut utiliser une autre clé ou méthode
    const mobileToken = localStorage.getItem('mobile_auth_token') || 
                        localStorage.getItem('token') ||
                        sessionStorage.getItem('auth_token');
    
    if (mobileToken && mobileToken.trim().length > 0) {
      // Synchroniser avec le token standard pour compatibilité
      localStorage.setItem('auth_token', mobileToken);
      return true;
    }
    
    // Si aucun token trouvé, rediriger vers login avec l'URL de destination
    const currentUrl = route.url.map(segment => segment.path).join('/');
    this.router.navigate(['/login'], { 
      queryParams: { next: currentUrl ? `/${currentUrl}` : '/profile' } 
    });
    return false;
  }
}
