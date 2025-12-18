import { Component, OnInit } from '@angular/core';
import { Router, ActivatedRoute } from '@angular/router';
import { ChartConfiguration, ChartData } from 'chart.js';
import { MobileDraftService } from '../../services/mobile-draft.service';

@Component({
  selector: 'app-mobile-form-a3',
  template: `
    <div class="mw-page">
      <div class="mw-topbar">
        <button class="mw-back" (click)="back()">←</button>
        <div>
          <div class="mw-title">Analyse & Graphiques</div>
          <div class="mw-sub">Pré-visualisation (simulée) comme mobile</div>
        </div>
      </div>

      <div class="mw-content">
        <div class="mw-card">
          <h2>Consommation réelle (24h)</h2>
          <div class="mw-chart">
            <canvas baseChart [data]="consumptionData" [options]="lineOptions" [type]="'line'"></canvas>
          </div>
        </div>

        <div class="mw-card">
          <h2>Production solaire potentielle (24h)</h2>
          <div class="mw-chart">
            <canvas baseChart [data]="productionData" [options]="lineOptions" [type]="'line'"></canvas>
          </div>
        </div>

        <div class="mw-card">
          <h2>SOC batterie simulée (24h)</h2>
          <div class="mw-chart">
            <canvas baseChart [data]="socData" [options]="lineOptions" [type]="'line'"></canvas>
          </div>
        </div>

        <div class="mw-card">
          <h2>Impact météo (ensoleillement)</h2>
          <div class="mw-chart">
            <canvas baseChart [data]="weatherData" [options]="barOptions" [type]="'bar'"></canvas>
          </div>
        </div>

        <div class="mw-footer">
          <button class="mw-btn" (click)="next()">Suivant</button>
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
        font-size: 16px;
        margin-bottom: 10px;
      }
      .mw-chart {
        height: 320px;
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
export class MobileFormA3Component implements OnInit {
  consumptionData: ChartData<'line'> = { labels: [], datasets: [] };
  productionData: ChartData<'line'> = { labels: [], datasets: [] };
  socData: ChartData<'line'> = { labels: [], datasets: [] };
  weatherData: ChartData<'bar'> = { labels: [], datasets: [] };

  lineOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: { legend: { display: false } },
    scales: { y: { beginAtZero: true } }
  };
  barOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: { legend: { display: false } },
    scales: { y: { beginAtZero: true, max: 100 } }
  };

  constructor(
    private router: Router, 
    private route: ActivatedRoute,
    private draft: MobileDraftService
  ) {}

  ngOnInit(): void {
    const a2 = this.draft.get<any>('a2_calc');
    const monthlyConsumption = a2?.monthlyConsumption ?? 50000;
    const solarSurface = a2?.solarSurface ?? 500;

    const labels = Array.from({ length: 24 }, (_, i) => `${i}h`);
    const baseHourly = monthlyConsumption / (30 * 24);

    const consumption = labels.map((_, i) => {
      const variation = baseHourly * 0.3 * (1 + (i % 12) / 12);
      return baseHourly + variation;
    });
    const production = labels.map((_, i) => {
      if (i < 6 || i > 18) return 0;
      const hourOfDay = i - 6;
      const distanceFromPeak = Math.abs(hourOfDay - 6);
      const efficiency = 1 - (distanceFromPeak / 6) * 0.5;
      return solarSurface * 0.2 * efficiency;
    });
    let currentSOC = 50;
    const batteryCapacity = monthlyConsumption * 0.1;
    const soc = labels.map((_, i) => {
      const net = production[i] - consumption[i];
      currentSOC = Math.max(0, Math.min(100, currentSOC + (net / batteryCapacity) * 100));
      return currentSOC;
    });

    const weather = labels.map((_, i) => {
      if (i < 6 || i > 18) return 0;
      const hourOfDay = i - 6;
      return 80 + (hourOfDay < 6 ? hourOfDay * 3 : (12 - hourOfDay) * 3);
    });

    this.consumptionData = {
      labels,
      datasets: [{ data: consumption, borderColor: '#4EA8DE', backgroundColor: 'rgba(78,168,222,0.20)', fill: true, tension: 0.35 }]
    };
    this.productionData = {
      labels,
      datasets: [{ data: production, borderColor: '#F4C430', backgroundColor: 'rgba(244,196,48,0.20)', fill: true, tension: 0.35 }]
    };
    this.socData = {
      labels,
      datasets: [{ data: soc, borderColor: '#6BCF9D', backgroundColor: 'rgba(107,207,157,0.20)', fill: true, tension: 0.35 }]
    };
    this.weatherData = {
      labels,
      datasets: [{ data: weather, backgroundColor: 'rgba(244,196,48,0.60)' }]
    };

    // Save computed daily sums for A4
    const dailyConsumption = consumption.reduce((a, b) => a + b, 0);
    const dailyProduction = production.reduce((a, b) => a + b, 0);
    this.draft.set('a3_calc', { dailyConsumption, dailyProduction });
  }

  next(): void {
    // Vérifier si on vient du workflow normal
    const workflow = this.route.snapshot.queryParamMap.get('workflow');
    const establishmentId = this.route.snapshot.queryParamMap.get('establishmentId');
    
    if (workflow === 'normal' && establishmentId) {
      // Workflow normal : aller directement vers les résultats complets (7 onglets + sidebar)
      this.router.navigate(['/mobile/results/comprehensive'], { queryParams: { establishmentId } });
    } else {
      // Workflow mobile : continuer vers A4
      this.router.navigate(['/mobile/a4']);
    }
  }

  back(): void {
    // Vérifier si on vient du workflow normal
    const workflow = this.route.snapshot.queryParamMap.get('workflow');
    const establishmentId = this.route.snapshot.queryParamMap.get('establishmentId');
    
    if (workflow === 'normal' && establishmentId) {
      this.router.navigate(['/mobile/a2'], { queryParams: { workflow: 'normal', establishmentId } });
    } else {
      this.router.navigate(['/mobile/a2']);
    }
  }
}
