import { Component } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-register',
  template: `
    <div class="register-container">
      <div class="register-card">
        <div class="register-header">
          <h1 class="gradient-text">Hospital Microgrid</h1>
          <p>Créez votre compte</p>
        </div>
        
        <form [formGroup]="registerForm" (ngSubmit)="onSubmit()" class="register-form">
          <div class="form-group">
            <label>Prénom</label>
            <input type="text" formControlName="firstName" placeholder="Votre prénom" />
            <span class="error" *ngIf="registerForm.get('firstName')?.hasError('required') && registerForm.get('firstName')?.touched">
              Prénom requis
            </span>
          </div>
          
          <div class="form-group">
            <label>Nom</label>
            <input type="text" formControlName="lastName" placeholder="Votre nom" />
            <span class="error" *ngIf="registerForm.get('lastName')?.hasError('required') && registerForm.get('lastName')?.touched">
              Nom requis
            </span>
          </div>
          
          <div class="form-group">
            <label>Email</label>
            <input type="email" formControlName="email" placeholder="votre@email.com" />
            <span class="error" *ngIf="registerForm.get('email')?.hasError('required') && registerForm.get('email')?.touched">
              Email requis
            </span>
            <span class="error" *ngIf="registerForm.get('email')?.hasError('email') && registerForm.get('email')?.touched">
              Email invalide
            </span>
          </div>
          
          <div class="form-group">
            <label>Mot de passe</label>
            <input type="password" formControlName="password" placeholder="••••••••" />
            <span class="error" *ngIf="registerForm.get('password')?.hasError('required') && registerForm.get('password')?.touched">
              Mot de passe requis
            </span>
            <span class="error" *ngIf="registerForm.get('password')?.hasError('minlength') && registerForm.get('password')?.touched">
              Le mot de passe doit contenir au moins 6 caractères
            </span>
          </div>
          
          <div class="form-group">
            <label>Confirmer le mot de passe</label>
            <input type="password" formControlName="confirmPassword" placeholder="••••••••" />
            <span class="error" *ngIf="registerForm.hasError('passwordMismatch') && registerForm.get('confirmPassword')?.touched">
              Les mots de passe ne correspondent pas
            </span>
          </div>
          
          <div class="error-message" *ngIf="errorMessage">
            {{ errorMessage }}
          </div>
          
          <button type="submit" class="btn-primary" [disabled]="registerForm.invalid || isLoading">
            <span *ngIf="!isLoading">S'inscrire</span>
            <span *ngIf="isLoading">Inscription en cours...</span>
          </button>
        </form>
        
        <div class="register-footer">
          <p>Déjà un compte ? <a (click)="goToLogin()" style="cursor: pointer; color: var(--medical-blue);">Se connecter</a></p>
        </div>
      </div>
    </div>
  `,
  styleUrls: ['./register.component.scss']
})
export class RegisterComponent {
  registerForm: FormGroup;
  isLoading = false;
  errorMessage = '';

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private router: Router
  ) {
    this.registerForm = this.fb.group({
      firstName: ['', [Validators.required]],
      lastName: ['', [Validators.required]],
      email: ['', [Validators.required, Validators.email]],
      password: ['', [Validators.required, Validators.minLength(6)]],
      confirmPassword: ['', [Validators.required]]
    }, { validators: this.passwordMatchValidator });
  }

  passwordMatchValidator(form: FormGroup) {
    const password = form.get('password');
    const confirmPassword = form.get('confirmPassword');
    
    if (password && confirmPassword && password.value !== confirmPassword.value) {
      confirmPassword.setErrors({ passwordMismatch: true });
      return { passwordMismatch: true };
    }
    return null;
  }

  onSubmit(): void {
    if (this.registerForm.valid) {
      this.isLoading = true;
      this.errorMessage = '';
      
      const { confirmPassword, ...registerData } = this.registerForm.value;
      
      this.authService.register(registerData).subscribe({
        next: () => {
          this.router.navigate(['/dashboard']);
        },
        error: (error) => {
          if (error.status === 0 || error.status === 504) {
            this.errorMessage = 'Impossible de se connecter au serveur. Vérifiez que le backend est démarré sur http://localhost:8080';
          } else if (error.status === 400) {
            this.errorMessage = error.error?.message || 'Données invalides. Vérifiez vos informations.';
          } else if (error.status === 409) {
            this.errorMessage = 'Cet email est déjà utilisé. Connectez-vous ou utilisez un autre email.';
          } else {
            this.errorMessage = error.error?.message || `Erreur lors de l'inscription (${error.status || 'inconnue'})`;
          }
          this.isLoading = false;
        }
      });
    }
  }

  goToLogin(): void {
    this.router.navigate(['/login']);
  }
}
