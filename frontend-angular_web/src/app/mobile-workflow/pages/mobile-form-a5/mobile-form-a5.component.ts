import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { EstablishmentService } from '../../../services/establishment.service';
import { MobileDraftService } from '../../services/mobile-draft.service';

@Component({
  selector: 'app-mobile-form-a5',
  template: `
    <div class="mw-page">
      <div class="mw-topbar">
        <button class="mw-back" (click)="back()">←</button>
        <div>
          <div class="mw-title">Choix du matériel</div>
          <div class="mw-sub">Étape 3/3</div>
        </div>
      </div>

      <div class="mw-content">
        <app-form-progress [currentStep]="3" [totalSteps]="3" [labels]="['Identification','Technique','Équipements']"></app-form-progress>

        <div class="mw-card mw-info">
          <div class="mw-info-ic">i</div>
          <div>
            <div class="mw-info-title">Recommandations</div>
            <div class="mw-muted">
              PV: {{ recommendedPVPower | number : '1.0-2' }} kW | Batterie: {{ recommendedBatteryCapacity | number : '1.0-2' }} kWh
            </div>
          </div>
        </div>

        <div class="mw-note">
          <div class="mw-note-ic">i</div>
          <div>
            Les prix affichés sont des estimations basées sur le marché marocain (2024). Les prix réels peuvent varier selon le fournisseur, la marque et les conditions du marché.
          </div>
        </div>

        <div class="mw-card">
          <h2>Panneaux Solaires</h2>
          <div class="mw-list">
            <button class="mw-item" *ngFor="let p of solarPanels" (click)="selectedPanel = p.id" [class.sel]="selectedPanel === p.id">
              <div>
                <div class="mw-name">{{ p.name }}</div>
                <div class="mw-small">Efficacité: {{ p.efficiency }}</div>
              </div>
              <div class="mw-price">{{ p.price }} DH</div>
            </button>
          </div>
        </div>

        <div class="mw-card">
          <h2>Batteries</h2>
          <div class="mw-list">
            <button class="mw-item" *ngFor="let b of batteries" (click)="selectedBattery = b.id" [class.sel]="selectedBattery === b.id">
              <div>
                <div class="mw-name">{{ b.name }}</div>
                <div class="mw-small">Cycles: {{ b.cycles }}</div>
              </div>
              <div class="mw-price">{{ b.price }} DH</div>
            </button>
          </div>
        </div>

        <div class="mw-card">
          <h2>Onduleurs</h2>
          <div class="mw-list">
            <button class="mw-item" *ngFor="let i of inverters" (click)="selectedInverter = i.id" [class.sel]="selectedInverter === i.id">
              <div>
                <div class="mw-name">{{ i.name }}</div>
                <div class="mw-small">Type: {{ i.type }}</div>
              </div>
              <div class="mw-price">{{ i.price }} DH</div>
            </button>
          </div>
        </div>

        <div class="mw-card">
          <h2>Régulateurs</h2>
          <div class="mw-list">
            <button class="mw-item" *ngFor="let c of controllers" (click)="selectedController = c.id" [class.sel]="selectedController === c.id">
              <div>
                <div class="mw-name">{{ c.name }}</div>
                <div class="mw-small">Type: {{ c.type }}</div>
              </div>
              <div class="mw-price">{{ c.price }} DH</div>
            </button>
          </div>

          <div class="mw-error" *ngIf="errorMessage">{{ errorMessage }}</div>
          <div class="mw-footer">
            <button class="mw-btn" (click)="finalize()" [disabled]="isCreating">
              {{ isCreating ? 'Création...' : 'Finaliser' }}
            </button>
          </div>
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
        max-width: 1100px;
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
      .mw-card h2 {
        font-size: 18px;
        margin-bottom: 10px;
      }
      .mw-muted {
        font-size: 13px;
        opacity: 0.75;
      }
      .mw-info {
        display: flex;
        gap: 14px;
        align-items: center;
        border: 2px solid rgba(78, 168, 222, 0.30);
      }
      .mw-info-ic {
        width: 48px;
        height: 48px;
        border-radius: 12px;
        display: grid;
        place-items: center;
        background: linear-gradient(135deg, var(--medical-blue), var(--solar-green));
        color: #fff;
        font-weight: 900;
      }
      .mw-info-title {
        font-weight: 900;
        margin-bottom: 4px;
      }
      .mw-note {
        display: flex;
        gap: 10px;
        align-items: flex-start;
        padding: 12px;
        border-radius: 12px;
        border: 1px solid rgba(59, 130, 246, 0.30);
        background: rgba(59, 130, 246, 0.08);
        font-size: 12px;
        opacity: 0.9;
      }
      .mw-note-ic {
        width: 20px;
        height: 20px;
        border-radius: 6px;
        display: grid;
        place-items: center;
        background: rgba(59, 130, 246, 0.18);
        font-weight: 900;
      }
      .mw-list {
        display: grid;
        gap: 10px;
      }
      .mw-item {
        width: 100%;
        text-align: left;
        border: 1px solid rgba(0, 0, 0, 0.10);
        background: #fff;
        border-radius: 14px;
        padding: 12px;
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 12px;
        cursor: pointer;
      }
      .mw-item.sel {
        border: 2px solid var(--medical-blue);
        background: rgba(78, 168, 222, 0.06);
      }
      .mw-name {
        font-weight: 800;
        font-size: 14px;
      }
      .mw-small {
        font-size: 11px;
        opacity: 0.7;
        margin-top: 4px;
      }
      .mw-price {
        font-weight: 900;
        color: var(--medical-blue);
        white-space: nowrap;
      }
      .mw-error {
        margin-top: 12px;
        color: var(--error);
        font-size: 13px;
      }
      .mw-footer {
        margin-top: 14px;
        display: flex;
        justify-content: flex-end;
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
    `
  ]
})
export class MobileFormA5Component implements OnInit {
  selectedPanel: string | null = null;
  selectedBattery: string | null = null;
  selectedInverter: string | null = null;
  selectedController: string | null = null;
  isCreating = false;
  errorMessage = '';

  recommendedPVPower = 0;
  recommendedBatteryCapacity = 0;

  solarPanels = [
    { id: 'panel1', name: 'Panneau Solaire Monocristallin 400W', price: '850', efficiency: '21.5%' },
    { id: 'panel2', name: 'Panneau Solaire Polycristallin 380W', price: '720', efficiency: '19.2%' },
    { id: 'panel3', name: 'Panneau Solaire Bifacial 450W', price: '1100', efficiency: '22.8%' },
    { id: 'panel4', name: 'Panneau Solaire PERC 410W', price: '950', efficiency: '21.8%' }
  ];
  batteries = [
    { id: 'battery1', name: 'Batterie Lithium-ion 10kWh', price: '45000', cycles: '6000' },
    { id: 'battery2', name: 'Batterie Lithium-ion 15kWh', price: '65000', cycles: '6000' },
    { id: 'battery3', name: 'Batterie Lithium Fer Phosphate 12kWh', price: '52000', cycles: '8000' },
    { id: 'battery4', name: 'Batterie AGM 20kWh', price: '38000', cycles: '1500' }
  ];
  inverters = [
    { id: 'inv1', name: 'Onduleur Hybride 5kW', price: '12000', type: 'Hybride' },
    { id: 'inv2', name: 'Onduleur Hybride 10kW', price: '22000', type: 'Hybride' },
    { id: 'inv3', name: 'Onduleur Grid-Tie 8kW', price: '15000', type: 'Grid-Tie' },
    { id: 'inv4', name: 'Onduleur Hybride 15kW', price: '32000', type: 'Hybride' }
  ];
  controllers = [
    { id: 'ctrl1', name: 'Regulateur MPPT 60A', price: '3500', type: 'MPPT' },
    { id: 'ctrl2', name: 'Regulateur MPPT 80A', price: '4800', type: 'MPPT' },
    { id: 'ctrl3', name: 'Regulateur MPPT 100A', price: '6200', type: 'MPPT' },
    { id: 'ctrl4', name: 'Regulateur PWM 50A', price: '1800', type: 'PWM' }
  ];

  constructor(private router: Router, private establishmentService: EstablishmentService, private draft: MobileDraftService) {}

  ngOnInit(): void {
    const a2 = this.draft.get<any>('a2_calc');
    const a4 = this.draft.get<any>('a4_calc');
    this.recommendedPVPower = a4?.recommendedPVPower ?? a2?.recommendedPVPower ?? 0;
    this.recommendedBatteryCapacity = a4?.recommendedBatteryCapacity ?? a2?.recommendedBatteryCapacity ?? 0;
  }

  finalize(): void {
    this.errorMessage = '';
    if (!this.selectedPanel || !this.selectedBattery || !this.selectedInverter || !this.selectedController) {
      this.errorMessage = 'Veuillez sélectionner tous les équipements.';
      return;
    }

    const a1 = this.draft.get<any>('a1');
    const a2 = this.draft.get<any>('a2_calc');
    if (!a1 || !a2 || a1.lat == null || a1.lng == null) {
      this.errorMessage = 'Données manquantes (A1/A2). Retournez aux étapes précédentes.';
      return;
    }

    const payload: any = {
      name: a1.name,
      type: a1.type,
      numberOfBeds: Number(a1.numberOfBeds),
      latitude: a1.lat,
      longitude: a1.lng,
      irradiationClass: a1.irradiationClass || null,
      installableSurfaceM2: a2.solarSurface,
      nonCriticalSurfaceM2: a2.nonCriticalSurface,
      monthlyConsumptionKwh: a2.monthlyConsumption,
      existingPvInstalled: false
    };

    this.isCreating = true;
    this.establishmentService.createEstablishment(payload).subscribe({
      next: (created) => {
        // Set selected establishment for the rest of the web app
        localStorage.setItem('selectedEstablishmentId', String(created.id));
        // Keep last EXISTANT calc for results fallback (avoid zeros when /recommendations is not ready)
        try {
          localStorage.setItem('mw_existing_last_calc', JSON.stringify(a2));
        } catch {}
        // Clear drafts like Flutter
        this.draft.clearAll();
        // Like Flutter A5: go directly to comprehensive results page
        this.router.navigate(['/mobile/results/comprehensive'], { queryParams: { establishmentId: created.id } });
      },
      error: (err) => {
        this.errorMessage = err?.error?.message || 'Erreur lors de la création de l’établissement.';
        this.isCreating = false;
      }
    });
  }

  back(): void {
    this.router.navigate(['/mobile/a2']);
  }
}

