import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { ChartConfiguration, ChartData } from 'chart.js';
import { HistoryService } from '../../services/history.service';
import { EstablishmentService } from '../../services/establishment.service';

@Component({
  selector: 'app-history',
  template: `
    <div class="history-container">
      <app-navigation></app-navigation>
      <div class="history-content">
        <div class="page-header">
          <h1>History</h1>
          <p>Long-term consumption and generation trends</p>
          <button class="refresh-btn" (click)="loadData()" [disabled]="isLoading">
            <span *ngIf="!isLoading">🔄 Actualiser</span>
            <span *ngIf="isLoading">Chargement...</span>
          </button>
        </div>
        
        <div *ngIf="errorMessage" class="error-message">
          {{ errorMessage }}
          <button class="create-btn" (click)="createEstablishment()" *ngIf="errorMessage.includes('Aucun établissement')">
            Créer un établissement
          </button>
        </div>
        
        <div *ngIf="!isLoading && savings" class="metrics-grid">
          <app-metric-card
            icon="📅"
            [label]="'Total Consumption'"
            [value]="formatValue(savings.annualConsumption / 12, 'MWh')"
            change="this month"
            [gradientColors]="['#4EA8DE', '#6BCF9D']">
          </app-metric-card>
          
          <app-metric-card
            icon="📈"
            [label]="'Total Generation'"
            [value]="formatValue(savings.annualPvProduction / 12, 'MWh')"
            [change]="formatChange(15.2)"
            [gradientColors]="['#6BCF9D', '#8B5CF6']">
          </app-metric-card>
          
          <app-metric-card
            icon="📉"
            [label]="'Total Savings'"
            [value]="formatValue(savings.annualSavings / 12, 'MWh')"
            [change]="formatChange(22.5)"
            [gradientColors]="['#8B5CF6', '#4EA8DE']">
          </app-metric-card>
          
          <app-metric-card
            icon="⚡"
            [label]="'Avg Efficiency'"
            [value]="formatValue(savings.autonomy, '%')"
            [change]="formatChange(5.8)"
            [gradientColors]="['#4EA8DE', '#8B5CF6']">
          </app-metric-card>
        </div>
        
        <div *ngIf="isLoading" class="loading-container">
          <p>Chargement des données historiques...</p>
        </div>
        
        <div *ngIf="!isLoading && monthlyData.labels && monthlyData.labels.length > 0" class="charts-row">
          <div class="chart-card">
            <h3>Monthly Consumption vs Generation</h3>
            <canvas baseChart
              [data]="monthlyData"
              [options]="chartOptions"
              [type]="'line'">
            </canvas>
          </div>
          
          <div class="chart-card">
            <h3>Monthly Savings Trend</h3>
            <canvas baseChart
              [data]="savingsData"
              [options]="chartOptions"
              [type]="'line'">
            </canvas>
          </div>
        </div>
        
        <div *ngIf="!isLoading && dailyData.labels && dailyData.labels.length > 0" class="chart-card full-width">
          <h3>Daily Load vs Solar Generation</h3>
          <canvas baseChart
            [data]="dailyData"
            [options]="chartOptions"
            [type]="'line'">
          </canvas>
        </div>
      </div>
    </div>
  `,
  styleUrls: ['./history.component.scss']
})
export class HistoryComponent implements OnInit {
  savings: any = null;
  isLoading = true;
  errorMessage = '';
  establishmentId: number | null = null;
  monthlyData: ChartData<'line'> = { labels: [], datasets: [] };
  savingsData: ChartData<'line'> = { labels: [], datasets: [] };
  dailyData: ChartData<'line'> = { labels: [], datasets: [] };

  chartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        display: true,
        position: 'top'
      }
    },
    scales: {
      y: {
        beginAtZero: true
      }
    }
  };

  constructor(
    private historyService: HistoryService,
    private establishmentService: EstablishmentService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadData();
  }

  loadData(): void {
    this.isLoading = true;
    this.errorMessage = '';
    
    this.establishmentService.getUserEstablishments().subscribe({
      next: (establishments) => {
        if (establishments.length === 0) {
          this.errorMessage = 'Aucun établissement trouvé. Veuillez créer un établissement d\'abord.';
          this.isLoading = false;
          return;
        }
        
        // Utiliser l'établissement sélectionné ou le premier disponible
        const selectedId = localStorage.getItem('selectedEstablishmentId');
        const establishmentId = selectedId ? parseInt(selectedId) : establishments[0].id;
        
        // Vérifier que l'établissement sélectionné existe toujours
        const establishment = establishments.find(e => e.id === establishmentId);
        if (!establishment) {
          localStorage.setItem('selectedEstablishmentId', establishments[0].id.toString());
          this.establishmentId = establishments[0].id;
        } else {
          this.establishmentId = establishmentId;
        }
        
        this.loadHistoryData();
      },
      error: (error) => {
        console.error('Error loading establishments:', error);
        if (error.status === 401) {
          this.errorMessage = 'Session expirée. Veuillez vous reconnecter.';
          setTimeout(() => {
            this.router.navigate(['/login']);
          }, 2000);
        } else if (error.status === 0) {
          this.errorMessage = 'Impossible de contacter le serveur. Vérifiez que le backend est démarré.';
        } else {
          this.errorMessage = 'Erreur lors du chargement des établissements.';
        }
        this.isLoading = false;
      }
    });
  }

  loadHistoryData(): void {
    if (!this.establishmentId) return;
    
    this.historyService.getSavings(this.establishmentId).subscribe({
      next: (savings) => {
        this.savings = savings;
        this.historyService.getHistoricalData(this.establishmentId!).subscribe({
          next: (historical) => {
            this.updateCharts(historical);
            this.isLoading = false;
          },
          error: () => {
            // Utiliser des données par défaut en cas d'erreur
            this.loadDefaultData();
            this.isLoading = false;
          }
        });
      },
      error: (error) => {
        this.errorMessage = 'Erreur lors du chargement des données historiques';
        this.isLoading = false;
      }
    });
  }

  updateCharts(historical: any): void {
    // Monthly data
    this.monthlyData = {
      labels: historical.monthly.map((m: any) => m.month),
      datasets: [
        {
          label: 'Consumption',
          data: historical.monthly.map((m: any) => m.consumption),
          borderColor: '#7C3AED',
          backgroundColor: 'rgba(124, 58, 237, 0.3)',
          tension: 0.4,
          fill: true
        },
        {
          label: 'Generation',
          data: historical.monthly.map((m: any) => m.generation),
          borderColor: '#00E5FF',
          backgroundColor: 'rgba(0, 229, 255, 0.3)',
          tension: 0.4,
          fill: true
        }
      ]
    };

    // Savings data
    this.savingsData = {
      labels: historical.monthly.map((m: any) => m.month),
      datasets: [{
        label: 'Savings',
        data: historical.monthly.map((m: any) => m.savings),
        borderColor: '#00E5FF',
        backgroundColor: 'rgba(0, 229, 255, 0.3)',
        tension: 0.4,
        fill: true
      }]
    };

    // Daily data
    this.dailyData = {
      labels: historical.daily.map((d: any) => d.date),
      datasets: [
        {
          label: 'Load',
          data: historical.daily.map((d: any) => d.load),
          borderColor: '#7C3AED',
          backgroundColor: 'transparent',
          tension: 0.4,
          borderWidth: 3
        },
        {
          label: 'Solar',
          data: historical.daily.map((d: any) => d.solar),
          borderColor: '#00E5FF',
          backgroundColor: 'transparent',
          tension: 0.4,
          borderWidth: 3
        }
      ]
    };
  }

  loadDefaultData(): void {
    // Données par défaut si le backend n'est pas disponible
    this.monthlyData = {
      labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
      datasets: [
        {
          label: 'Consumption',
          data: [2400, 2210, 2290, 2000, 2181, 2500],
          borderColor: '#7C3AED',
          backgroundColor: 'rgba(124, 58, 237, 0.3)',
          tension: 0.4,
          fill: true
        },
        {
          label: 'Generation',
          data: [1200, 1290, 1500, 1800, 2100, 2300],
          borderColor: '#00E5FF',
          backgroundColor: 'rgba(0, 229, 255, 0.3)',
          tension: 0.4,
          fill: true
        }
      ]
    };

    this.savingsData = {
      labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
      datasets: [{
        label: 'Savings',
        data: [400, 450, 520, 580, 650, 720],
        borderColor: '#00E5FF',
        backgroundColor: 'rgba(0, 229, 255, 0.3)',
        tension: 0.4,
        fill: true
      }]
    };

    this.dailyData = {
      labels: ['1', '5', '10', '15', '20', '25', '30'],
      datasets: [
        {
          label: 'Load',
          data: [2400, 2210, 2290, 2000, 2181, 2500, 2400],
          borderColor: '#7C3AED',
          backgroundColor: 'transparent',
          tension: 0.4,
          borderWidth: 3
        },
        {
          label: 'Solar',
          data: [1200, 1290, 1500, 1800, 2100, 2300, 2200],
          borderColor: '#00E5FF',
          backgroundColor: 'transparent',
          tension: 0.4,
          borderWidth: 3
        }
      ]
    };
  }

  formatValue(value: number, unit: string): string {
    if (unit === '%') {
      return `${value.toFixed(0)}%`;
    } else if (unit === 'MWh') {
      return `${value.toFixed(2)} ${unit}`;
    }
    return `${value.toFixed(1)} ${unit}`;
  }

  formatChange(change: number): string {
    const sign = change >= 0 ? '+' : '';
    return `${sign}${change.toFixed(1)}%`;
  }

  createEstablishment(): void {
    this.router.navigate(['/create-establishment']);
  }
}
