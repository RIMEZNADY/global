import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { DashboardService } from '../../../services/dashboard.service';
import { EstablishmentService } from '../../../services/establishment.service';

@Component({
  selector: 'app-mobile-calculation-results',
  template: `
    <div class="mw-page">
      <div class="mw-topbar">
        <button class="mw-back" (click)="back()">←</button>
        <div>
          <div class="mw-title">Résultats (Calcul)</div>
          <div class="mw-sub">Comme CalculationResultsPage (mobile)</div>
        </div>
      </div>

      <div class="mw-content">
        <div class="mw-card" *ngIf="isLoading">Chargement...</div>
        <div class="mw-card" *ngIf="!isLoading && errorMessage">
          <div class="mw-error">{{ errorMessage }}</div>
          <button class="mw-mini" (click)="load()">Réessayer</button>
        </div>

        <ng-container *ngIf="!isLoading && !errorMessage">
          <div class="mw-card" *ngIf="recommendations">
            <h2>Recommandations</h2>
            <div class="mw-grid">
              <div class="mw-metric">
                <div class="mw-k">PV recommandé</div>
                <div class="mw-v">{{ recommendations.recommendedPvPowerKwc | number:'1.0-2' }} <span>kWc</span></div>
              </div>
              <div class="mw-metric">
                <div class="mw-k">Surface PV</div>
                <div class="mw-v">{{ recommendations.recommendedPvSurfaceM2 | number:'1.0-0' }} <span>m²</span></div>
              </div>
              <div class="mw-metric">
                <div class="mw-k">Batterie recommandée</div>
                <div class="mw-v">{{ recommendations.recommendedBatteryCapacityKwh | number:'1.0-2' }} <span>kWh</span></div>
              </div>
              <div class="mw-metric">
                <div class="mw-k">Autonomie estimée</div>
                <div class="mw-v">{{ recommendations.estimatedEnergyAutonomy | number:'1.0-1' }} <span>%</span></div>
              </div>
            </div>
            <div class="mw-muted" *ngIf="recommendations.description">{{ recommendations.description }}</div>
          </div>

          <div class="mw-card" *ngIf="savings">
            <h2>Économies</h2>
            <div class="mw-grid">
              <div class="mw-metric">
                <div class="mw-k">Consommation annuelle</div>
                <div class="mw-v">{{ savings.annualConsumption | number:'1.0-0' }} <span>kWh</span></div>
              </div>
              <div class="mw-metric">
                <div class="mw-k">Production PV annuelle</div>
                <div class="mw-v">{{ savings.annualPvProduction | number:'1.0-0' }} <span>kWh</span></div>
              </div>
              <div class="mw-metric">
                <div class="mw-k">Économies annuelles</div>
                <div class="mw-v">{{ savings.annualSavings | number:'1.0-0' }} <span>DH</span></div>
              </div>
              <div class="mw-metric">
                <div class="mw-k">Autonomie</div>
                <div class="mw-v">{{ savings.autonomy | number:'1.0-1' }} <span>%</span></div>
              </div>
            </div>
          </div>

          <div class="mw-footer">
            <button class="mw-btn" (click)="goComprehensive()">Voir résultats complets</button>
          </div>
        </ng-container>
      </div>
    </div>
  `,
  styles: [
    `
      .mw-page { min-height: 100vh; background: var(--off-white); }
      .mw-topbar { display:flex; gap:12px; align-items:center; padding:16px 18px; background:#fff; border-bottom:1px solid rgba(0,0,0,0.06); }
      .mw-back { width:44px; height:44px; border-radius:12px; border:1px solid rgba(0,0,0,0.08); background:#fff; cursor:pointer; font-size:18px; }
      .mw-title { font-weight:900; }
      .mw-sub { font-size:12px; opacity:.7; }
      .mw-content { max-width: 1100px; margin:0 auto; padding:16px; display:grid; gap:16px; }
      .mw-card { background:#fff; border-radius:16px; padding:16px; border:1px solid rgba(0,0,0,0.06); box-shadow:0 6px 18px rgba(0,0,0,0.06); }
      .mw-card h2 { font-size:18px; margin-bottom:12px; }
      .mw-grid { display:grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap:12px; }
      .mw-metric { padding:14px; border-radius:14px; border:1px solid rgba(0,0,0,0.08); }
      .mw-k { font-size:12px; opacity:.7; margin-bottom:6px; font-weight:700; }
      .mw-v { font-weight:900; font-size:20px; }
      .mw-v span { font-size:13px; font-weight:600; opacity:.7; }
      .mw-muted { font-size:12px; opacity:.75; margin-top:10px; }
      .mw-error { color: var(--error); font-weight:800; }
      .mw-mini { margin-top:10px; padding:8px 10px; border-radius:10px; border:1px solid rgba(0,0,0,0.12); background:#fff; cursor:pointer; font-weight:800; }
      .mw-footer { display:flex; justify-content:flex-end; }
      .mw-btn { padding:12px 18px; border-radius:14px; border:none; background: linear-gradient(135deg, var(--medical-blue), var(--solar-green)); color:#fff; font-weight:900; cursor:pointer; }
    `
  ]
})
export class MobileCalculationResultsComponent implements OnInit {
  establishmentId: number | null = null;
  isLoading = true;
  errorMessage = '';

  recommendations: any = null;
  savings: any = null;

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private establishmentService: EstablishmentService,
    private dashboardService: DashboardService
  ) {}

  ngOnInit(): void {
    const id = this.route.snapshot.queryParamMap.get('establishmentId') || localStorage.getItem('selectedEstablishmentId');
    this.establishmentId = id ? parseInt(id) : null;
    this.load();
  }

  load(): void {
    if (!this.establishmentId) {
      this.isLoading = false;
      this.errorMessage = 'Aucun établissement sélectionné.';
      return;
    }
    this.isLoading = true;
    this.errorMessage = '';

    this.establishmentService.getRecommendations(this.establishmentId).subscribe({
      next: (rec) => {
        this.recommendations = rec;
        this.dashboardService.getSavings(this.establishmentId!).subscribe({
          next: (sav) => {
            this.savings = sav;
            localStorage.setItem('selectedEstablishmentId', String(this.establishmentId));
            this.isLoading = false;
          },
          error: () => {
            this.errorMessage = 'Erreur lors du chargement des économies.';
            this.isLoading = false;
          }
        });
      },
      error: () => {
        this.errorMessage = 'Erreur lors du chargement des recommandations.';
        this.isLoading = false;
      }
    });
  }

  goComprehensive(): void {
    if (!this.establishmentId) return;
    this.router.navigate(['/mobile/results/comprehensive'], { queryParams: { establishmentId: this.establishmentId } });
  }

  back(): void {
    this.router.navigate(['/mobile/result-choice'], { queryParams: { establishmentId: this.establishmentId } });
  }
}


