import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { ChartConfiguration, ChartData } from 'chart.js';
import { DashboardService, DashboardMetrics } from '../../services/dashboard.service';
import { EstablishmentService } from '../../services/establishment.service';
import { forkJoin } from 'rxjs';

@Component({
  selector: 'app-dashboard',
  template: `
    <div class="dashboard-container">
      <app-navigation></app-navigation>
      <div class="dashboard-content">
        <div class="dashboard-header">
          <h1>Dashboard</h1>
          <p>Real-time monitoring and analytics</p>
          <button class="refresh-btn" (click)="loadData()" [disabled]="isLoading">
            <span *ngIf="!isLoading">🔄 Actualiser</span>
            <span *ngIf="isLoading">Chargement...</span>
          </button>
        </div>
        
        <div *ngIf="successMessage" class="success-message">
          {{ successMessage }}
        </div>
        
        <div *ngIf="errorMessage" class="error-message">
          {{ errorMessage }}
          <button class="create-btn" (click)="createEstablishment()" *ngIf="errorMessage.includes('Aucun établissement')">
            Créer un établissement
          </button>
        </div>
        
        <div *ngIf="!isLoading && metrics" class="metrics-grid">
          <app-metric-card
            icon="⚡"
            [label]="'Current Load'"
            [value]="formatValue(metrics.currentLoad, 'kW')"
            [change]="formatChange(metrics.currentLoadChange)"
            [gradientColors]="['#4EA8DE', '#6BCF9D']">
          </app-metric-card>
          
          <app-metric-card
            icon="📈"
            [label]="'Solar Generation'"
            [value]="formatValue(metrics.solarGeneration, 'kW')"
            [change]="formatChange(metrics.solarGenerationChange)"
            [gradientColors]="['#6BCF9D', '#8B5CF6']">
          </app-metric-card>
          
          <app-metric-card
            icon="📊"
            [label]="'System Efficiency'"
            [value]="formatValue(metrics.systemEfficiency, '%')"
            [change]="formatChange(metrics.efficiencyChange)"
            [gradientColors]="['#8B5CF6', '#4EA8DE']">
          </app-metric-card>
          
          <app-metric-card
            icon="🔋"
            [label]="'Battery Status'"
            [value]="formatValue(metrics.batteryStatus, '%')"
            [change]="formatChange(metrics.batteryStatusChange)"
            [gradientColors]="['#4EA8DE', '#8B5CF6']">
          </app-metric-card>
        </div>
        
        <div *ngIf="isLoading" class="loading-container">
          <p>Chargement des données...</p>
        </div>
        
        <div *ngIf="!isLoading && energyFlowData" class="charts-row">
          <div class="chart-card">
            <h3>Energy Flow (24h)</h3>
            <canvas baseChart
              [data]="energyFlowData"
              [options]="chartOptions"
              [type]="'line'">
            </canvas>
          </div>
          
          <div class="chart-card">
            <h3>System Efficiency</h3>
            <canvas baseChart
              [data]="efficiencyData"
              [options]="chartOptions"
              [type]="'bar'">
            </canvas>
          </div>
        </div>
        
        <div *ngIf="!isLoading && loadDistributionData" class="chart-card full-width">
          <h3>Load Distribution</h3>
          <canvas baseChart
            [data]="loadDistributionData"
            [options]="chartOptions"
            [type]="'line'">
          </canvas>
        </div>
      </div>
    </div>
  `,
  styleUrls: ['./dashboard.component.scss']
})
export class DashboardComponent implements OnInit {
  metrics: DashboardMetrics | null = null;
  isLoading = true;
  errorMessage = '';
  successMessage = '';
  establishmentId: number | null = null;
  energyFlowData: ChartData<'line'> = {
    labels: ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00', '24:00'],
    datasets: [
      {
        label: 'Solar',
        data: [0, 100, 2290, 3490, 2100, 200, 0],
        borderColor: '#00E5FF',
        backgroundColor: 'rgba(0, 229, 255, 0.3)',
        tension: 0.4,
        fill: true
      },
      {
        label: 'Grid',
        data: [2400, 2210, 1200, 400, 1398, 2800, 2400],
        borderColor: '#7C3AED',
        backgroundColor: 'rgba(124, 58, 237, 0.3)',
        tension: 0.4,
        fill: true
      }
    ]
  };

  efficiencyData: ChartData<'bar'> = {
    labels: ['00', '04', '08', '12', '16', '20', '24'],
    datasets: [{
      label: 'Efficiency %',
      data: [78, 82, 88, 95, 92, 85, 80],
      backgroundColor: 'rgba(0, 229, 255, 0.8)',
      borderColor: '#00E5FF',
      borderWidth: 1
    }]
  };

  loadDistributionData: ChartData<'line'> = {
    labels: ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00', '24:00'],
    datasets: [
      {
        label: 'Load',
        data: [2800, 2000, 2181, 2500, 2100, 2800, 2800],
        borderColor: '#00E5FF',
        backgroundColor: 'transparent',
        tension: 0.4,
        borderWidth: 3
      },
      {
        label: 'Battery',
        data: [1200, 1290, 800, 0, 500, 1200, 1200],
        borderColor: '#40E0D0',
        backgroundColor: 'transparent',
        tension: 0.4,
        borderWidth: 3
      }
    ]
  };

  chartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        display: true,
        position: 'top',
        labels: {
          color: '#3A3A3A',
          font: {
            family: 'Inter',
            size: 12
          }
        }
      }
    },
    scales: {
      y: {
        beginAtZero: true,
        ticks: {
          color: '#3A3A3A',
          font: {
            family: 'Inter',
            size: 11
          }
        },
        grid: {
          color: 'rgba(0, 0, 0, 0.05)'
        }
      },
      x: {
        ticks: {
          color: '#3A3A3A',
          font: {
            family: 'Inter',
            size: 11
          }
        },
        grid: {
          display: false
        }
      }
    }
  };

  constructor(
    private dashboardService: DashboardService,
    private establishmentService: EstablishmentService,
    private router: Router
  ) {}

  ngOnInit(): void {
    // Vérifier si un établissement vient d'être créé
    const urlParams = new URLSearchParams(window.location.search);
    if (urlParams.get('created') === 'true') {
      this.successMessage = 'Établissement créé avec succès !';
      setTimeout(() => {
        this.successMessage = '';
      }, 5000);
    }
    
    this.loadData();
  }

  loadData(): void {
    this.isLoading = true;
    this.errorMessage = '';
    
    this.establishmentService.getUserEstablishments().subscribe({
      next: (establishments) => {
        if (establishments.length > 0) {
          this.establishmentId = establishments[0].id;
          this.loadDashboardData();
        } else {
          this.errorMessage = 'Aucun établissement trouvé. Veuillez créer un établissement d\'abord.';
          this.isLoading = false;
        }
      },
      error: (error) => {
        this.errorMessage = 'Erreur lors du chargement des établissements';
        this.isLoading = false;
      }
    });
  }

  createEstablishment(): void {
    this.router.navigate(['/institution-choice']);
  }

  loadDashboardData(): void {
    if (!this.establishmentId) return;
    
    forkJoin({
      establishment: this.establishmentService.getEstablishment(this.establishmentId),
      savings: this.dashboardService.getSavings(this.establishmentId),
      simulation: this.dashboardService.simulateEnergyFlow(this.establishmentId, 1)
    }).subscribe({
      next: (data) => {
        this.metrics = this.dashboardService.calculateMetrics(data.establishment, data.savings);
        this.updateChartsFromSimulation(data.simulation);
        this.isLoading = false;
      },
      error: (error) => {
        // En cas d'erreur, utiliser des données par défaut
        this.metrics = {
          currentLoad: 2.8,
          solarGeneration: 1.2,
          systemEfficiency: 92,
          batteryStatus: 78,
          currentLoadChange: 2.4,
          solarGenerationChange: 12.5,
          efficiencyChange: 5.2,
          batteryStatusChange: -1.8
        };
        this.isLoading = false;
        console.error('Erreur lors du chargement des données:', error);
      }
    });
  }

  updateChartsFromSimulation(simulation: any): void {
    if (simulation && simulation.steps) {
      const steps = simulation.steps.slice(0, 7); // Prendre 7 points pour le graphique
      const labels = steps.map((step: any, index: number) => {
        const date = new Date(step.datetime);
        return `${date.getHours().toString().padStart(2, '0')}:00`;
      });
      
      this.energyFlowData = {
        labels,
        datasets: [
          {
            label: 'Solar',
            data: steps.map((step: any) => step.pvProduction || 0),
            borderColor: '#00E5FF',
            backgroundColor: 'rgba(0, 229, 255, 0.3)',
            tension: 0.4,
            fill: true
          },
          {
            label: 'Grid',
            data: steps.map((step: any) => step.gridImport || 0),
            borderColor: '#7C3AED',
            backgroundColor: 'rgba(124, 58, 237, 0.3)',
            tension: 0.4,
            fill: true
          }
        ]
      };
      
      this.loadDistributionData = {
        labels,
        datasets: [
          {
            label: 'Load',
            data: steps.map((step: any) => step.predictedConsumption || 0),
            borderColor: '#00E5FF',
            backgroundColor: 'transparent',
            tension: 0.4,
            borderWidth: 3
          },
          {
            label: 'Battery',
            data: steps.map((step: any) => step.socBattery || 0),
            borderColor: '#40E0D0',
            backgroundColor: 'transparent',
            tension: 0.4,
            borderWidth: 3
          }
        ]
      };
    }
  }

  formatValue(value: number, unit: string): string {
    if (unit === '%') {
      return `${value.toFixed(0)}%`;
    } else if (unit === 'kW') {
      if (value >= 1000) {
        return `${(value / 1000).toFixed(2)} MW`;
      }
      return `${value.toFixed(1)} ${unit}`;
    }
    return `${value.toFixed(1)} ${unit}`;
  }

  formatChange(change: number): string {
    const sign = change >= 0 ? '+' : '';
    return `${sign}${change.toFixed(1)}%`;
  }
}
