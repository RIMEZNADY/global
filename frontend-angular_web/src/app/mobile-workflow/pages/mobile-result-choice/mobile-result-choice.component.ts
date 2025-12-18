import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { AiService } from '../../../services/ai.service';

@Component({
  selector: 'app-mobile-result-choice',
  template: `
    <div class="mw-page">
      <div class="mw-topbar">
        <button class="mw-back" (click)="back()">←</button>
        <div>
          <div class="mw-title">Choix du mode de résultats</div>
          <div class="mw-sub">IA vs Calcul (fallback)</div>
        </div>
      </div>

      <div class="mw-content">
        <div class="mw-card">
          <p *ngIf="isChecking">Vérification de la disponibilité IA...</p>
          <p *ngIf="!isChecking && error" class="mw-warn">{{ error }}</p>
          <p *ngIf="!isChecking && iaAvailable" class="mw-ok">IA disponible.</p>
        </div>

        <div class="mw-actions">
          <button class="mw-btn" (click)="goCalc()">Voir résultats (Calcul)</button>
          <button class="mw-btn mw-alt" (click)="goIa()" [disabled]="isChecking || !iaAvailable">Voir résultats (IA)</button>
          <button class="mw-link" (click)="recheck()" [disabled]="isChecking">Re-tester l’IA</button>
        </div>
      </div>
    </div>
  `,
  styles: [
    `
      .mw-page {
        min-height: 100vh;
        background: var(--off-white);
      }
      .mw-topbar {
        display: flex;
        gap: 12px;
        align-items: center;
        padding: 16px 18px;
        background: #fff;
        border-bottom: 1px solid rgba(0, 0, 0, 0.06);
      }
      .mw-back {
        width: 44px;
        height: 44px;
        border-radius: 12px;
        border: 1px solid rgba(0, 0, 0, 0.08);
        background: #fff;
        cursor: pointer;
        font-size: 18px;
      }
      .mw-title {
        font-weight: 900;
      }
      .mw-sub {
        font-size: 12px;
        opacity: 0.7;
      }
      .mw-content {
        max-width: 760px;
        margin: 0 auto;
        padding: 16px;
        display: grid;
        gap: 16px;
      }
      .mw-card {
        background: #fff;
        border-radius: 16px;
        padding: 16px;
        border: 1px solid rgba(0, 0, 0, 0.06);
        box-shadow: 0 6px 18px rgba(0, 0, 0, 0.06);
      }
      .mw-warn {
        color: #b8860b;
      }
      .mw-ok {
        color: #059669;
        font-weight: 800;
      }
      .mw-actions {
        display: grid;
        gap: 10px;
      }
      .mw-btn {
        padding: 12px 18px;
        border-radius: 14px;
        border: none;
        background: linear-gradient(135deg, var(--medical-blue), var(--solar-green));
        color: #fff;
        font-weight: 900;
        cursor: pointer;
      }
      .mw-btn:disabled {
        opacity: 0.6;
        cursor: not-allowed;
      }
      .mw-alt {
        background: linear-gradient(135deg, var(--solar-yellow), var(--medical-blue));
      }
      .mw-link {
        background: transparent;
        border: none;
        color: var(--medical-blue);
        font-weight: 800;
        cursor: pointer;
      }
      .mw-link:disabled {
        opacity: 0.6;
        cursor: not-allowed;
      }
    `
  ]
})
export class MobileResultChoiceComponent implements OnInit {
  isChecking = true;
  iaAvailable = false;
  error: string | null = null;
  establishmentId: number | null = null;

  constructor(private ai: AiService, private router: Router, private route: ActivatedRoute) {}

  ngOnInit(): void {
    const id = this.route.snapshot.queryParamMap.get('establishmentId');
    this.establishmentId = id ? parseInt(id) : null;
    this.recheck();
  }

  recheck(): void {
    if (!this.establishmentId) {
      this.isChecking = false;
      this.iaAvailable = false;
      this.error = 'Aucun établissement sélectionné.';
      return;
    }
    this.isChecking = true;
    this.error = null;
    this.ai.getForecast(this.establishmentId, 1).subscribe({
      next: () => {
        this.isChecking = false;
        this.iaAvailable = true;
      },
      error: () => {
        this.isChecking = false;
        this.iaAvailable = false;
        this.error = 'IA indisponible (fallback calcul).';
      }
    });
  }

  goCalc(): void {
    if (this.establishmentId) {
      localStorage.setItem('selectedEstablishmentId', String(this.establishmentId));
    }
    this.router.navigate(['/mobile/results/calculation'], { queryParams: { establishmentId: this.establishmentId } });
  }

  goIa(): void {
    if (!this.iaAvailable) {
      this.goCalc();
      return;
    }
    if (this.establishmentId) {
      localStorage.setItem('selectedEstablishmentId', String(this.establishmentId));
    }
    this.router.navigate(['/ai-prediction'], { queryParams: { from: 'mobile' } });
  }

  back(): void {
    this.router.navigate(['/mobile/choice']);
  }
}
