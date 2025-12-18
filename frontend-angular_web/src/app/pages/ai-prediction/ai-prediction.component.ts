import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { ChartConfiguration, ChartData } from 'chart.js';
import { AiService, LongTermForecastResponse } from '../../services/ai.service';
import { EstablishmentService } from '../../services/establishment.service';

@Component({
  selector: 'app-ai-prediction',
  template: `
    <div class="ai-prediction-container">
      <app-navigation></app-navigation>
      <div class="ai-prediction-content">
        <div class="page-header">
          <h1>AI Prediction</h1>
          <p>Machine learning-powered 24-hour energy demand forecasting</p>
        </div>
        
        <div class="controls">
          <div class="control-group">
            <label>Horizon de prédiction:</label>
            <select [(ngModel)]="selectedHorizonDays" (change)="loadForecast()">
              <option [value]="7">7 jours</option>
              <option [value]="14">14 jours</option>
              <option [value]="30">30 jours</option>
            </select>
          </div>
          <div class="control-group">
            <label>Mode:</label>
            <select [(ngModel)]="forecastMode" (change)="onModeChange()">
              <option value="horizon">Horizon</option>
              <option value="seasonal">Saisonnier</option>
            </select>
          </div>
          <div class="control-group" *ngIf="forecastMode === 'seasonal'">
            <label>Saison:</label>
            <select [(ngModel)]="selectedSeason" (change)="loadForecast()">
              <option value="ete">Été</option>
              <option value="hiver">Hiver</option>
              <option value="printemps">Printemps</option>
              <option value="automne">Automne</option>
            </select>
          </div>
          <button class="refresh-btn" (click)="loadForecast()" [disabled]="isLoading">
            <span *ngIf="!isLoading">🔄 Actualiser</span>
            <span *ngIf="isLoading">Chargement...</span>
          </button>
        </div>
        
        <div *ngIf="isLoading" class="loading">
          <p>Chargement des prédictions...</p>
        </div>
        
        <div *ngIf="errorMessage" class="error">
          {{ errorMessage }}
          <button class="create-btn" (click)="createEstablishment()" *ngIf="errorMessage.includes('Aucun établissement')">
            Créer un établissement
          </button>
        </div>
        
        <div *ngIf="forecast && !isLoading" class="forecast-content">
          <div class="chart-card">
            <h3>Prédictions de consommation ({{ selectedHorizonDays }} jours)</h3>
            <canvas baseChart
              [data]="forecastChartData"
              [options]="chartOptions"
              [type]="'line'">
            </canvas>
          </div>
          
          <div class="forecast-info">
            <div class="info-card">
              <h4>Tendance</h4>
              <p>{{ forecast.trend }}</p>
            </div>
            <div class="info-card">
              <h4>Méthode</h4>
              <p>{{ forecast.method }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  `,
  styleUrls: ['./ai-prediction.component.scss']
})
export class AiPredictionComponent implements OnInit {
  selectedHorizonDays = 7;
  forecastMode = 'horizon';
  selectedSeason = 'ete';
  forecast: LongTermForecastResponse | null = null;
  isLoading = false;
  errorMessage = '';
  establishmentId: number | null = null;
  
  forecastChartData: ChartData<'line'> = {
    labels: [],
    datasets: []
  };

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
    private aiService: AiService,
    private establishmentService: EstablishmentService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadEstablishment();
  }

  loadEstablishment(): void {
    this.establishmentService.getUserEstablishments().subscribe({
      next: (establishments) => {
        if (establishments.length === 0) {
          this.errorMessage = 'Aucun établissement trouvé. Veuillez créer un établissement d\'abord.';
          return;
        }
        
        // Utiliser l'établissement sélectionné ou le premier disponible
        const selectedId = localStorage.getItem('selectedEstablishmentId');
        const establishmentId = selectedId ? parseInt(selectedId) : establishments[0].id;
        
        // Vérifier que l'établissement sélectionné existe toujours
        const establishment = establishments.find(e => e.id === establishmentId);
        if (!establishment) {
          // Si l'établissement sélectionné n'existe plus, utiliser le premier
          localStorage.setItem('selectedEstablishmentId', establishments[0].id.toString());
          this.establishmentId = establishments[0].id;
        } else {
          this.establishmentId = establishmentId;
        }
        
        this.loadForecast();
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
      }
    });
  }

  loadForecast(): void {
    if (!this.establishmentId) return;
    
    this.isLoading = true;
    this.errorMessage = '';
    
    const forecast$ = this.forecastMode === 'seasonal'
      ? this.aiService.getSeasonalForecast(this.establishmentId, this.selectedSeason)
      : this.aiService.getForecast(this.establishmentId, this.selectedHorizonDays);
    
    forecast$.subscribe({
      next: (forecast) => {
        this.forecast = forecast;
        this.updateChartData();
        this.isLoading = false;
      },
      error: (error) => {
        this.errorMessage = error.error?.message || 'Erreur lors du chargement des prédictions';
        this.isLoading = false;
      }
    });
  }

  onModeChange(): void {
    if (this.forecastMode === 'seasonal' && !this.selectedSeason) {
      this.selectedSeason = 'ete';
    }
    this.loadForecast();
  }

  updateChartData(): void {
    if (!this.forecast) return;
    
    const labels = this.forecast.predictions.map(p => `Jour ${p.day}`);
    const consumptionData = this.forecast.predictions.map(p => p.predictedConsumption);
    const pvData = this.forecast.predictions.map(p => p.predictedPvProduction);
    
    this.forecastChartData = {
      labels,
      datasets: [
        {
          label: 'Consommation prédite (kWh)',
          data: consumptionData,
          borderColor: '#7C3AED',
          backgroundColor: 'rgba(124, 58, 237, 0.3)',
          tension: 0.4,
          fill: true
        },
        {
          label: 'Production PV prédite (kWh)',
          data: pvData,
          borderColor: '#00E5FF',
          backgroundColor: 'rgba(0, 229, 255, 0.3)',
          tension: 0.4,
          fill: true
        }
      ]
    };
  }

  createEstablishment(): void {
    this.router.navigate(['/institution-choice']);
  }
}
