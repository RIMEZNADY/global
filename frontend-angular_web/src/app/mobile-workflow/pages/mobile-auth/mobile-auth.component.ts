import { Component } from '@angular/core';
import { Router } from '@angular/router';

@Component({
  selector: 'app-mobile-auth',
  template: `
    <div class="mw-auth">
      <div class="mw-card">
        <div class="mw-brand">
          <div class="mw-badge">🏥</div>
          <h2>Bienvenue</h2>
          <p>Connectez-vous ou créez un compte pour commencer</p>
        </div>

        <button class="mw-btn mw-btn-primary" (click)="goLogin()">
          Connexion <span class="mw-arrow">→</span>
        </button>

        <button class="mw-btn mw-btn-secondary" (click)="goRegister()">
          Inscription <span class="mw-arrow">→</span>
        </button>

        <div class="mw-footer">Microgrid Intelligent pour Hôpitaux</div>
      </div>
    </div>
  `,
  styles: [
    `
      .mw-auth {
        min-height: 100vh;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 24px;
        background: linear-gradient(135deg, var(--off-white), rgba(78, 168, 222, 0.06));
      }

      .mw-card {
        width: 100%;
        max-width: 520px;
        background: white;
        border-radius: 20px;
        padding: 28px;
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.08);
        border: 1px solid rgba(0, 0, 0, 0.05);
      }

      .mw-brand {
        text-align: center;
        margin-bottom: 26px;
      }

      .mw-badge {
        width: 78px;
        height: 78px;
        margin: 0 auto 14px;
        border-radius: 18px;
        display: flex;
        align-items: center;
        justify-content: center;
        background: linear-gradient(135deg, var(--medical-blue), var(--solar-green));
        color: #fff;
        font-size: 34px;
        box-shadow: 0 12px 26px rgba(78, 168, 222, 0.28);
      }

      .mw-brand h2 {
        font-size: 28px;
        margin-bottom: 8px;
      }

      .mw-brand p {
        font-size: 14px;
        opacity: 0.75;
      }

      .mw-btn {
        width: 100%;
        padding: 14px 16px;
        border-radius: 16px;
        font-weight: 700;
        border: none;
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 10px;
        transition: transform 0.15s ease, box-shadow 0.15s ease;
      }

      .mw-btn:active {
        transform: translateY(1px);
      }

      .mw-btn-primary {
        margin-top: 8px;
        background: linear-gradient(135deg, var(--medical-blue), var(--solar-green));
        color: #fff;
        box-shadow: 0 10px 22px rgba(78, 168, 222, 0.22);
      }

      .mw-btn-secondary {
        margin-top: 12px;
        background: #fff;
        color: var(--medical-blue);
        border: 2px solid rgba(78, 168, 222, 0.45);
      }

      .mw-arrow {
        font-weight: 900;
      }

      .mw-footer {
        margin-top: 22px;
        text-align: center;
        font-size: 12px;
        opacity: 0.55;
      }
    `
  ]
})
export class MobileAuthComponent {
  constructor(private router: Router) {}

  goLogin(): void {
    // Reuse existing web login page
    this.router.navigate(['/login'], { queryParams: { next: '/mobile/choice' } });
  }

  goRegister(): void {
    // Reuse existing web register page
    this.router.navigate(['/register'], { queryParams: { next: '/mobile/choice' } });
  }
}

