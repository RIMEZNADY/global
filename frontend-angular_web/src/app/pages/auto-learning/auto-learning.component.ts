import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { AiService, MLMetricsResponse } from '../../services/ai.service';

@Component({
  selector: 'app-auto-learning',
  template: `
    <div class="auto-learning-container">
      <app-navigation></app-navigation>
      <div class="auto-learning-content">
        <div class="page-header">
          <h1>Auto-Learning & Métriques ML</h1>
          <p>Métriques réelles du modèle Machine Learning et historique d'entraînement</p>
          <button class="refresh-btn" (click)="loadMetrics()" [disabled]="isLoading || isRetraining">
            <span *ngIf="!isLoading">🔄 Actualiser</span>
            <span *ngIf="isLoading">Chargement...</span>
          </button>
        </div>
        
        <div *ngIf="isLoading" class="loading">
          <p>Chargement des métriques...</p>
        </div>
        
        <div *ngIf="errorMessage" class="error">
          <div class="error-content">
            <span>{{ errorMessage }}</span>
            <div class="error-actions">
              <button class="retry-btn" (click)="loadMetrics()" *ngIf="!isLoading">
                Réessayer
              </button>
            </div>
          </div>
        </div>
        
        <div *ngIf="metrics && !isLoading" class="metrics-content">
          <div class="metrics-cards">
            <div class="metric-card-large">
              <div class="metric-header">
                <span class="metric-icon"></span>
                <span class="metric-help">?</span>
              </div>
              <div class="metric-value">{{ metrics.test.mae.toFixed(2) }} kWh</div>
              <div class="metric-label">MAE (Test)</div>
              <div class="metric-description">Erreur moyenne absolue sur les données de test</div>
            </div>
            
            <div class="metric-card-large">
              <div class="metric-header">
                <span class="metric-icon"></span>
                <span class="metric-help">?</span>
              </div>
              <div class="metric-value">{{ metrics.test.rmse.toFixed(2) }} kWh</div>
              <div class="metric-label">RMSE (Test)</div>
              <div class="metric-description">Erreur quadratique moyenne sur les données de test</div>
            </div>
            
            <div class="metric-card-large">
              <div class="metric-header">
                <span class="metric-icon">%</span>
                <span class="metric-help">?</span>
              </div>
              <div class="metric-value">{{ (metrics.test.mape * 100).toFixed(2) }}%</div>
              <div class="metric-label">MAPE (Test)</div>
              <div class="metric-description">Erreur moyenne absolue en pourcentage</div>
            </div>
          </div>
          
          <div class="info-section">
            <div class="info-card">
              <h3>Informations Modèle</h3>
              <div class="info-row">
                <span>Type de modèle</span>
                <span>{{ metrics.meta.model }}</span>
              </div>
              <div class="info-row">
                <span>Nombre de features</span>
                <span>{{ metrics.meta.features }}</span>
              </div>
              <div class="info-row">
                <span>Échantillons d'entraînement</span>
                <span>{{ metrics.meta.train_rows }}</span>
              </div>
              <div class="info-row">
                <span>Échantillons de test</span>
                <span>{{ metrics.meta.test_rows }}</span>
              </div>
              <div class="info-row" *ngIf="metrics.meta.timestamp">
                <span>Dernière mise à jour</span>
                <span>{{ formatTimestamp(metrics.meta.timestamp) }}</span>
              </div>
            </div>
            
            <div class="info-card">
              <h3>Comparaison Train vs Test</h3>
              <div class="comparison-row">
                <div class="comparison-item">
                  <span class="comparison-label">MAE</span>
                  <div class="comparison-values">
                    <span class="train">Train: {{ metrics.train.mae.toFixed(2) }} kWh</span>
                    <span class="test">Test: {{ metrics.test.mae.toFixed(2) }} kWh</span>
                  </div>
                </div>
                <div class="comparison-item">
                  <span class="comparison-label">RMSE</span>
                  <div class="comparison-values">
                    <span class="train">Train: {{ metrics.train.rmse.toFixed(2) }} kWh</span>
                    <span class="test">Test: {{ metrics.test.rmse.toFixed(2) }} kWh</span>
                  </div>
                </div>
                <div class="comparison-item">
                  <span class="comparison-label">MAPE</span>
                  <div class="comparison-values">
                    <span class="train">Train: {{ (metrics.train.mape * 100).toFixed(2) }}%</span>
                    <span class="test">Test: {{ (metrics.test.mape * 100).toFixed(2) }}%</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
          <div class="retrain-section">
            <button class="btn-primary" (click)="retrain()" [disabled]="isRetraining">
              <span *ngIf="!isRetraining">🔄 Rentraîner le modèle</span>
              <span *ngIf="isRetraining">Rentraînement en cours...</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  `,
  styleUrls: ['./auto-learning.component.scss']
})
export class AutoLearningComponent implements OnInit {
  metrics: MLMetricsResponse | null = null;
  isLoading = true;
  errorMessage = '';
  isRetraining = false;

  constructor(
    private aiService: AiService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadMetrics();
  }

  loadMetrics(): void {
    this.isLoading = true;
    this.errorMessage = '';
    
    this.aiService.getMetrics().subscribe({
      next: (metrics) => {
        this.metrics = metrics;
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading metrics:', error);
        if (error.status === 0 || error.status === 404) {
          this.errorMessage = 'Le service AI n\'est pas disponible. Veuillez vérifier que le service est démarré sur http://localhost:8000';
        } else if (error.status === 500) {
          this.errorMessage = 'Erreur serveur lors du chargement des métriques. Le modèle n\'a peut-être pas encore été entraîné.';
        } else {
          this.errorMessage = error.error?.message || error.message || 'Erreur lors du chargement des métriques';
        }
        this.isLoading = false;
      }
    });
  }

  retrain(): void {
    this.isRetraining = true;
    
    this.aiService.retrain().subscribe({
      next: () => {
        this.isRetraining = false;
        this.loadMetrics();
        alert('Modèle rentraîné avec succès');
      },
      error: (error) => {
        this.isRetraining = false;
        alert('Erreur lors du rentraînement: ' + (error.error?.message || error.message));
      }
    });
  }

  formatTimestamp(timestamp: string): string {
    try {
      const date = new Date(timestamp);
      return `${date.getDate()}/${date.getMonth() + 1}/${date.getFullYear()} ${date.getHours()}:${date.getMinutes().toString().padStart(2, '0')}`;
    } catch {
      return timestamp;
    }
  }
}
