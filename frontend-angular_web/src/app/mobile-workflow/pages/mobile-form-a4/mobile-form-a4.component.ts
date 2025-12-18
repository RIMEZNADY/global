import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { MobileDraftService } from '../../services/mobile-draft.service';

@Component({
  selector: 'app-mobile-form-a4',
  template: `
    <div class="mw-page">
      <div class="mw-topbar">
        <button class="mw-back" (click)="back()">←</button>
        <div>
          <div class="mw-title">Recommandations</div>
          <div class="mw-sub">Basées sur votre consommation et votre surface disponible</div>
        </div>
      </div>

      <div class="mw-content">
        <div class="mw-card mw-rec" [style.--g]="'linear-gradient(135deg,#10B981,#059669)'">
          <div class="mw-ic"></div>
          <div class="mw-rec-body">
            <div class="mw-rec-title">Économie possible</div>
            <div class="mw-rec-value">{{ annualSavings | number:'1.0-0' }} <span>DH/an</span></div>
          </div>
        </div>

        <div class="mw-card mw-rec" [style.--g]="'linear-gradient(135deg,var(--solar-green),#0891B2)'">
          <div class="mw-ic"></div>
          <div class="mw-rec-body">
            <div class="mw-rec-title">Pourcentage d'autonomie possible</div>
            <div class="mw-rec-value">{{ autonomyPercentage | number:'1.0-1' }} <span>%</span></div>
          </div>
        </div>

        <div class="mw-card mw-rec" [style.--g]="'linear-gradient(135deg,#FFD700,#FFA500)'">
          <div class="mw-ic"></div>
          <div class="mw-rec-body">
            <div class="mw-rec-title">Puissance PV recommandée</div>
            <div class="mw-rec-value">{{ recommendedPVPower | number:'1.0-2' }} <span>kW</span></div>
          </div>
        </div>

        <div class="mw-card mw-rec" [style.--g]="'linear-gradient(135deg,#8B5CF6,var(--medical-blue))'">
          <div class="mw-ic"></div>
          <div class="mw-rec-body">
            <div class="mw-rec-title">Capacité batterie recommandée</div>
            <div class="mw-rec-value">{{ recommendedBatteryCapacity | number:'1.0-2' }} <span>kWh</span></div>
          </div>
        </div>

        <div class="mw-footer">
          <button class="mw-btn" (click)="next()">Continuer</button>
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
        max-width: 1000px;
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
        margin-bottom: 14px;
      }
      .mw-rec {
        display: flex;
        align-items: center;
        gap: 16px;
      }
      .mw-ic {
        width: 56px;
        height: 56px;
        display: grid;
        place-items: center;
        border-radius: 12px;
        background: var(--g);
        color: #fff;
        font-size: 22px;
        box-shadow: 0 10px 18px rgba(0,0,0,0.12);
      }
      .mw-rec-title {
        font-weight: 800;
        opacity: 0.8;
        font-size: 13px;
      }
      .mw-rec-value {
        margin-top: 6px;
        font-weight: 950;
        font-size: 28px;
        color: var(--soft-grey);
      }
      .mw-rec-value span {
        font-weight: 700;
        font-size: 14px;
        opacity: 0.7;
      }
      .mw-footer {
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
    `
  ]
})
export class MobileFormA4Component implements OnInit {
  autonomyPercentage = 0;
  recommendedPVPower = 0;
  recommendedBatteryCapacity = 0;
  annualSavings = 0;

  constructor(private router: Router, private draft: MobileDraftService) {}

  ngOnInit(): void {
    const a2 = this.draft.get<any>('a2_calc');
    const a3 = this.draft.get<any>('a3_calc');
    const solarSurface = a2?.solarSurface ?? 500;
    const monthlyConsumption = a2?.monthlyConsumption ?? 50000;
    const dailyConsumption = a3?.dailyConsumption ?? monthlyConsumption / 30;
    const dailyProduction = a3?.dailyProduction ?? solarSurface * 0.2 * 12;

    this.autonomyPercentage = Math.max(0, Math.min(100, (dailyProduction / dailyConsumption) * 100));
    this.recommendedPVPower = solarSurface * 0.2;
    const avgHourly = monthlyConsumption / (30 * 24);
    this.recommendedBatteryCapacity = avgHourly * 12;
    const annualGridConsumption = monthlyConsumption * 12 * (1 - this.autonomyPercentage / 100);
    this.annualSavings = annualGridConsumption * 1.5;

    this.draft.set('a4_calc', {
      autonomyPercentage: this.autonomyPercentage,
      recommendedPVPower: this.recommendedPVPower,
      recommendedBatteryCapacity: this.recommendedBatteryCapacity,
      annualSavings: this.annualSavings
    });
  }

  next(): void {
    this.router.navigate(['/mobile/a5']);
  }

  back(): void {
    this.router.navigate(['/mobile/a3']);
  }
}

