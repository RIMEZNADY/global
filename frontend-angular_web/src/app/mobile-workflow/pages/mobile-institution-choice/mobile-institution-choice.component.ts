import { Component } from '@angular/core';
import { Router } from '@angular/router';

@Component({
  selector: 'app-mobile-institution-choice',
  template: `
    <div class="mw-choice">
      <div class="mw-card">
        <div class="mw-header">
          <h1 class="gradient-text">SOLAR MEDICAL</h1>
          <p>Choisissez votre workflow (Mobile)</p>
        </div>

        <div class="mw-actions">
          <button class="mw-choice-btn mw-existing" (click)="goExisting()">
            <div class="mw-label">EXISTANT</div>
          </button>

          <button class="mw-choice-btn mw-new" (click)="goNew()">
            <div class="mw-label">NEW</div>
          </button>
        </div>
      </div>
    </div>
  `,
  styles: [
    `
      .mw-choice {
        min-height: 100vh;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 24px;
        background: linear-gradient(135deg, var(--off-white), rgba(78, 168, 222, 0.06));
      }
      .mw-card {
        width: 100%;
        max-width: 760px;
        background: #fff;
        border-radius: 20px;
        padding: 26px;
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.08);
        border: 1px solid rgba(0, 0, 0, 0.05);
      }
      .mw-header {
        text-align: center;
        margin-bottom: 22px;
      }
      .mw-header h1 {
        font-size: 32px;
        font-weight: 900;
        margin-bottom: 6px;
      }
      .mw-header p {
        opacity: 0.7;
      }
      .mw-actions {
        display: grid;
        grid-template-columns: 1fr;
        gap: 14px;
      }
      .mw-choice-btn {
        width: 100%;
        border: none;
        cursor: pointer;
        border-radius: 18px;
        padding: 24px 26px;
        display: flex;
        align-items: center;
        justify-content: center;
        text-align: center;
        color: #fff;
        transition: transform 0.15s ease, box-shadow 0.15s ease;
      }
      .mw-choice-btn:hover {
        transform: translateY(-1px);
        box-shadow: 0 10px 24px rgba(0, 0, 0, 0.14);
      }
      .mw-label {
        font-size: 24px;
        font-weight: 900;
        letter-spacing: 2px;
        line-height: 1.2;
      }
      .mw-existing {
        background: linear-gradient(135deg, var(--medical-blue), var(--solar-green));
      }
      .mw-new {
        background: linear-gradient(135deg, var(--solar-green), var(--solar-yellow));
      }
    `
  ]
})
export class MobileInstitutionChoiceComponent {
  constructor(private router: Router) {}

  goExisting(): void {
    this.router.navigate(['/mobile/map-selection'], { queryParams: { next: '/mobile/a1' } });
  }

  goNew(): void {
    this.router.navigate(['/mobile/b1']);
  }
}

