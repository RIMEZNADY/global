import { Component } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-login',
  template: `
    <div class="login-container">
      <div class="login-card">
        <div class="login-header">
          <h1 class="gradient-text">Hospital Microgrid</h1>
          <p>Connectez-vous à votre compte</p>
        </div>
        
        <form [formGroup]="loginForm" (ngSubmit)="onSubmit()" class="login-form">
          <div class="form-group">
            <label>Email</label>
            <input type="email" formControlName="email" placeholder="votre@email.com" />
            <span class="error" *ngIf="loginForm.get('email')?.hasError('required') && loginForm.get('email')?.touched">
              Email requis
            </span>
          </div>
          
          <div class="form-group">
            <label>Mot de passe</label>
            <input type="password" formControlName="password" placeholder="••••••••" />
            <span class="error" *ngIf="loginForm.get('password')?.hasError('required') && loginForm.get('password')?.touched">
              Mot de passe requis
            </span>
          </div>
          
          <div class="error-message" *ngIf="errorMessage">
            {{ errorMessage }}
          </div>
          
          <button type="submit" class="btn-primary" [disabled]="loginForm.invalid || isLoading">
            <span *ngIf="!isLoading">Se connecter</span>
            <span *ngIf="isLoading">Connexion...</span>
          </button>
        </form>
        
        <div class="login-footer">
          <p>Pas encore de compte ? <a (click)="register()" style="cursor: pointer; color: var(--medical-blue); text-decoration: none; font-weight: 600;">S'inscrire</a></p>
        </div>
      </div>
      
      <button class="discover-btn" (click)="goToHome()">
        <span>Découvrir</span>
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polyline points="9 18 15 12 9 6"></polyline>
        </svg>
      </button>
    </div>
  `,
  styleUrls: ['./login.component.scss']
})
export class LoginComponent {
  loginForm: FormGroup;
  isLoading = false;
  errorMessage = '';

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private router: Router,
    private route: ActivatedRoute
  ) {
    this.loginForm = this.fb.group({
      email: ['', [Validators.required, Validators.email]],
      password: ['', [Validators.required, Validators.minLength(6)]]
    });
  }

  onSubmit(): void {
    if (this.loginForm.valid) {
      this.isLoading = true;
      this.errorMessage = '';
      
      this.authService.login(this.loginForm.value).subscribe({
        next: () => {
          // Attendre un peu pour s'assurer que le token est bien stocké
          setTimeout(() => {
            const next = this.route.snapshot.queryParamMap.get('next');
            // Si un paramètre 'next' est fourni (ex: depuis mobile ou page protégée), l'utiliser
            // Sinon, rediriger vers la page d'accueil (home)
            this.router.navigate([next || '/home']);
          }, 100);
        },
        error: (error) => {
          if (error.status === 0 || error.status === 504) {
            this.errorMessage = 'Impossible de se connecter au serveur. Vérifiez que le backend est démarré sur http://localhost:8080';
          } else if (error.status === 401) {
            this.errorMessage = 'Email ou mot de passe incorrect';
          } else if (error.status === 404) {
            this.errorMessage = 'Endpoint non trouvé. Vérifiez la configuration du backend';
          } else {
            this.errorMessage = error.error?.message || `Erreur de connexion (${error.status || 'inconnue'})`;
          }
          this.isLoading = false;
        }
      });
    }
  }

  register(): void {
    const next = this.route.snapshot.queryParamMap.get('next');
    this.router.navigate(['/register'], next ? { queryParams: { next } } : undefined);
  }

  goToHome(): void {
    this.router.navigate(['/home']);
  }
}
