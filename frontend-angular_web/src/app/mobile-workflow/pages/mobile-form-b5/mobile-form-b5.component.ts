import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { EstablishmentService } from '../../../services/establishment.service';
import { MobileDraftService } from '../../services/mobile-draft.service';

@Component({
  selector: 'app-mobile-form-b5',
  template: `
    <div class="mw-page">
      <div class="mw-topbar">
        <button class="mw-back" (click)="back()">←</button>
        <div>
          <div class="mw-title">Décision Finale</div>
          <div class="mw-sub">NEW · Étape 5/5</div>
        </div>
      </div>

      <div class="mw-content">
        <div class="mw-card" *ngIf="isLoading">
          <p>Calcul des recommandations...</p>
        </div>

        <div class="mw-card" *ngIf="errorMessage && !isLoading">
          <p class="mw-error">{{ errorMessage }}</p>
          <button class="mw-mini" (click)="load()">Réessayer</button>
        </div>

        <div class="mw-card" *ngIf="!isLoading && !errorMessage && calculations && economy">
          <h2>Prévisions Techniques</h2>
          <div class="mw-grid">
            <div class="mw-metric">
              <div class="mw-k">Consommation annuelle prévue</div>
              <div class="mw-v">{{ calculations.annualConsumption | number:'1.0-0' }} <span>kWh</span></div>
            </div>
            <div class="mw-metric">
              <div class="mw-k">Puissance PV requise</div>
              <div class="mw-v">{{ calculations.requiredPVPower | number:'1.0-2' }} <span>kW</span></div>
            </div>
            <div class="mw-metric">
              <div class="mw-k">Surface PV nécessaire</div>
              <div class="mw-v">{{ calculations.necessaryPVSurface | number:'1.0-0' }} <span>m²</span></div>
            </div>
            <div class="mw-metric">
              <div class="mw-k">Autonomie énergétique</div>
              <div class="mw-v">{{ calculations.autonomyPercentage | number:'1.0-1' }} <span>%</span></div>
            </div>
            <div class="mw-metric">
              <div class="mw-k">Besoin batterie</div>
              <div class="mw-v">{{ calculations.batteryNeed | number:'1.0-2' }} <span>kWh</span></div>
            </div>
          </div>
        </div>

        <div class="mw-card" *ngIf="!isLoading && !errorMessage && calculations && economy">
          <h2>Économie Prévisionnelle</h2>
          <div class="mw-grid">
            <div class="mw-metric">
              <div class="mw-k">Coût d’installation (estim.)</div>
              <div class="mw-v">{{ economy.installationCost | number:'1.0-0' }} <span>DH</span></div>
            </div>
            <div class="mw-metric">
              <div class="mw-k">Économie annuelle</div>
              <div class="mw-v">{{ economy.annualSavings | number:'1.0-0' }} <span>DH</span></div>
            </div>
            <div class="mw-metric">
              <div class="mw-k">ROI</div>
              <div class="mw-v">{{ economy.roi | number:'1.0-1' }} <span>ans</span></div>
            </div>
            <div class="mw-metric">
              <div class="mw-k">Réduction CO₂</div>
              <div class="mw-v">{{ economy.co2Reduction | number:'1.0-2' }} <span>t/an</span></div>
            </div>
          </div>
        </div>

        <div class="mw-footer" *ngIf="!isLoading && !errorMessage">
          <button class="mw-btn" (click)="finish()" [disabled]="!establishmentId">Finaliser</button>
        </div>
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
      .mw-error { color: var(--error); font-weight:800; }
      .mw-mini { margin-top:10px; padding:8px 10px; border-radius:10px; border:1px solid rgba(0,0,0,0.12); background:#fff; cursor:pointer; font-weight:800; }
      .mw-footer { display:flex; justify-content:flex-end; }
      .mw-btn { padding:12px 18px; border-radius:14px; border:none; background: linear-gradient(135deg, var(--medical-blue), var(--solar-green)); color:#fff; font-weight:900; cursor:pointer; }
      .mw-btn:disabled { opacity:.6; cursor:not-allowed; }
    `
  ]
})
export class MobileFormB5Component implements OnInit {
  isLoading = true;
  errorMessage = '';
  establishmentId: number | null = null;
  calculations: any = null;
  economy: any = null;

  constructor(private router: Router, private establishmentService: EstablishmentService, private draft: MobileDraftService) {}

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.isLoading = true;
    this.errorMessage = '';

    const b1 = this.draft.get<any>('b1');
    const b2 = this.draft.get<any>('b2_calc');
    const b3 = this.draft.get<any>('b3');
    if (!b1 || !b2 || !b3 || b1.lat == null || b1.lng == null) {
      this.isLoading = false;
      this.errorMessage = 'Données manquantes (B1/B2/B3).';
      return;
    }

    const payload: any = {
      name: b3.type, // Flutter uses hospitalType display as name; here backend expects name string
      type: b3.type, // already backend value from selector
      numberOfBeds: Math.round((b2.population || 0) / 100) || 1,
      latitude: b1.lat,
      longitude: b1.lng,
      irradiationClass: b1.irradiationClass || null,
      projectBudgetDh: b2.budget,
      totalAvailableSurfaceM2: b2.totalSurface,
      installableSurfaceM2: b2.solarSurface,
      populationServed: b2.population,
      projectPriority: b3.priorite
    };

    this.establishmentService.createEstablishment(payload).subscribe({
      next: (created) => {
        this.establishmentId = created.id;
        // Load backend recommendations + savings like Flutter B5
        this.establishmentService.getRecommendations(created.id).subscribe({
          next: (rec) => {
            this.establishmentService.getSavings(created.id, 1.2).subscribe({
              next: (sav) => {
                this.calculations = {
                  annualConsumption: sav.annualConsumption,
                  requiredPVPower: rec.recommendedPvPowerKwc ?? rec['recommendedPvPower'] ?? rec.recommendedPvPowerKwc,
                  necessaryPVSurface: rec.recommendedPvSurfaceM2 ?? rec['recommendedPvSurface'],
                  autonomyPercentage: rec.estimatedEnergyAutonomy ?? rec['energyAutonomy'] ?? rec.estimatedEnergyAutonomy,
                  batteryNeed: rec.recommendedBatteryCapacityKwh ?? rec['recommendedBatteryCapacity']
                };
                const installationCost = b2.budget * 0.8;
                const annualPvProduction = sav.annualPvProduction ?? sav.annualPvEnergy ?? 0;
                const co2Reduction = (annualPvProduction * 0.5) / 1000;
                this.economy = {
                  installationCost,
                  annualSavings: sav.annualSavings,
                  roi: rec.estimatedROI ?? rec['roi'],
                  co2Reduction
                };
                localStorage.setItem('selectedEstablishmentId', String(created.id));
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
      },
      error: (err) => {
        this.errorMessage = err?.error?.message || 'Erreur lors de la création de l’établissement.';
        this.isLoading = false;
      }
    });
  }

  finish(): void {
    if (!this.establishmentId) return;
    localStorage.setItem('selectedEstablishmentId', String(this.establishmentId));
    this.draft.clearAll();
    // Like Flutter: go to comprehensive results after creation
    this.router.navigate(['/mobile/results/comprehensive'], { queryParams: { establishmentId: this.establishmentId } });
  }

  back(): void {
    this.router.navigate(['/mobile/b4']);
  }
}

