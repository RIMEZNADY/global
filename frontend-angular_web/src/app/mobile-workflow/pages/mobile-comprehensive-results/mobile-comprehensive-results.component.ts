import { Component, OnDestroy, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { forkJoin, of } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { ChartConfiguration, ChartData } from 'chart.js';
import { AiService, AnomalyGraphResponse, LongTermForecastResponse, MlRecommendationsResponse } from '../../../services/ai.service';
import { DashboardService } from '../../../services/dashboard.service';
import { Establishment, EstablishmentRecommendations, EstablishmentService } from '../../../services/establishment.service';
import { AuthService } from '../../../services/auth.service';
import { TooltipComponent } from '../../../components/tooltip/tooltip.component';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { NgChartsModule } from 'ng2-charts';
import jsPDF from 'jspdf';

@Component({
  selector: 'app-mobile-comprehensive-results',
  standalone: true,
  imports: [CommonModule, RouterModule, NgChartsModule, TooltipComponent],
  template: `
    <div class="dashboard-layout">
      <!-- Left Sidebar -->
      <aside class="dashboard-sidebar">
        <div class="sidebar-header">
          <div class="sidebar-logo">
            <div class="logo-icon">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"></polygon>
              </svg>
            </div>
            <div class="logo-text">
              <div class="logo-title">Hospital</div>
              <div class="logo-subtitle">Microgrid</div>
            </div>
          </div>
        </div>
        <nav class="sidebar-nav">
          <a [routerLink]="['/profile']" class="nav-item">
            <span class="nav-icon"></span>
            <span class="nav-label">Profil</span>
          </a>
          <a [routerLink]="['/establishments']" class="nav-item">
            <span class="nav-icon"></span>
            <span class="nav-label">Établissements</span>
          </a>
          <div class="nav-item active">
            <span class="nav-icon"></span>
            <span class="nav-label">Résultats</span>
          </div>
        </nav>
        <div class="sidebar-footer">
          <button class="logout-btn" (click)="logout()">
            
            <span class="nav-label">Déconnexion</span>
          </button>
        </div>
      </aside>

      <!-- Main Content Area -->
      <div class="dashboard-main">
        <!-- Top Header -->
        <header class="dashboard-header">
          <div class="header-left">
            <button class="header-back" (click)="back()" title="Retour">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M19 12H5M12 19l-7-7 7-7"/>
              </svg>
            </button>
            <div class="header-title-group">
              <h1 class="header-title">Résultats Complets</h1>
              <p class="header-subtitle" *ngIf="establishment">{{ establishment.name }}</p>
            </div>
          </div>
          <div class="header-actions">
            <button class="action-btn pause-btn" [class.paused]="!autoRefreshEnabled" (click)="toggleAutoRefresh()" [title]="getPauseButtonTitle()">
              <svg *ngIf="autoRefreshEnabled" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect x="6" y="4" width="4" height="16" rx="1"/>
                <rect x="14" y="4" width="4" height="16" rx="1"/>
              </svg>
              <svg *ngIf="!autoRefreshEnabled" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polygon points="5 3 19 12 5 21 5 3"/>
              </svg>
              <span>{{ autoRefreshEnabled ? 'Pause' : 'Reprendre' }}</span>
            </button>
            <button class="action-btn" (click)="load()" title="Actualiser">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8M21 3v5h-5M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16M3 21v-5h5"/>
              </svg>
              <span>Actualiser</span>
            </button>
            <button class="action-btn" (click)="exportPdf()" title="Exporter PDF">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M7 10l5 5 5-5M12 15V3"/>
              </svg>
              <span>Exporter PDF</span>
            </button>
          </div>
        </header>

        <!-- Content Area -->
        <main class="dashboard-content">
          <!-- Loading State -->
          <div class="content-loading" *ngIf="isLoading">
            <div class="loading-spinner"></div>
            <p>Chargement des résultats...</p>
          </div>

          <!-- Error State -->
          <div class="content-error" *ngIf="!isLoading && errorMessage">
            <div class="error-icon"></div>
            <h3>Erreur de chargement</h3>
            <p>{{ errorMessage }}</p>
            <button class="btn-primary" (click)="load()">Réessayer</button>
          </div>

          <!-- Main Content -->
          <ng-container *ngIf="!isLoading && !errorMessage">
            <!-- Tab Navigation -->
            <div class="content-tabs">
              <button 
                class="tab-btn" 
                [class.active]="activeTab === 'overview'" 
                (click)="setTab('overview')">
                <span class="tab-icon"></span>
                <span class="tab-label">Vue d'ensemble</span>
              </button>
              <button 
                class="tab-btn" 
                [class.active]="activeTab === 'financial'" 
                (click)="setTab('financial')">
                <span class="tab-icon"></span>
                <span class="tab-label">Financier</span>
              </button>
              <button 
                class="tab-btn" 
                [class.active]="activeTab === 'environmental'" 
                (click)="setTab('environmental')">
            
                <span class="tab-label">Environnemental</span>
              </button>
              <button 
                class="tab-btn" 
                [class.active]="activeTab === 'technical'" 
                (click)="setTab('technical')">
                
                <span class="tab-label">Technique</span>
              </button>
              <button 
                class="tab-btn" 
                [class.active]="activeTab === 'comparison'" 
                (click)="setTab('comparison')">
             
                <span class="tab-label">Comparatif</span>
              </button>
              <button 
                class="tab-btn" 
                [class.active]="activeTab === 'alerts'" 
                (click)="setTab('alerts')">
               
                <span class="tab-label">Alertes</span>
              </button>
              <button 
                class="tab-btn" 
                [class.active]="activeTab === 'ai'" 
                (click)="setTab('ai')">
              
                <span class="tab-label">IA</span>
              </button>
            </div>

            <!-- Tab Content -->
            <div class="tab-content">
              <!-- OVERVIEW TAB -->
              <ng-container *ngIf="activeTab === 'overview'">
                <div class="content-grid">
                  <!-- Global Score Card -->
                  <div class="card card-hero">
                    <div class="card-header">
                      <h2 class="card-title">Score Global</h2>
                      <div class="card-badge score-badge">
                        {{ n(comprehensive?.globalScore?.score) | number:'1.0-1' }}/100
                      </div>
                    </div>
                    <div class="score-display">
                      <div class="score-circle">
                        <svg class="score-ring" viewBox="0 0 120 120">
                          <circle cx="60" cy="60" r="54" fill="none" stroke="rgba(78,168,222,0.1)" stroke-width="8"/>
                          <circle 
                            cx="60" cy="60" r="54" 
                            fill="none" 
                            stroke="url(#scoreGradient)" 
                            stroke-width="8"
                            stroke-linecap="round"
                            [attr.stroke-dasharray]="(n(comprehensive?.globalScore?.score) / 100) * 339.29 + ', 339.29'"
                            transform="rotate(-90 60 60)"/>
                          <defs>
                            <linearGradient id="scoreGradient" x1="0%" y1="0%" x2="100%" y2="100%">
                              <stop offset="0%" style="stop-color:#4EA8DE"/>
                              <stop offset="100%" style="stop-color:#6BCF9D"/>
                            </linearGradient>
                          </defs>
                        </svg>
                        <div class="score-value">{{ n(comprehensive?.globalScore?.score) | number:'1.0-1' }}</div>
                      </div>
                      <div class="score-stars">
                        <span 
                          *ngFor="let star of getStarsArray(); let i = index" 
                          class="star"
                          [class.filled]="star.filled"
                          [class.half]="star.half">
                          <svg viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" stroke-width="0.5">
                            <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/>
                          </svg>
                        </span>
                      </div>
                    </div>
                  </div>

                  <!-- Key Metrics Grid -->
                  <div class="card">
                    <h3 class="card-title">Indicateurs Clés</h3>
                    <div class="metrics-grid">
                      <div class="metric-item">
                        <div class="metric-icon"></div>
                        <div class="metric-content">
                          <div class="metric-label">
                            Autonomie énergétique
                            <app-tooltip text="Pourcentage de la consommation énergétique totale couverte par la production solaire et le stockage. Une autonomie élevée réduit la dépendance au réseau électrique."></app-tooltip>
                          </div>
                          <div class="metric-value">{{ energyAutonomyValue() | number:'1.0-1' }}%</div>
                        </div>
                      </div>
                      <div class="metric-item">
                        <div class="metric-icon"></div>
                        <div class="metric-content">
                          <div class="metric-label">
                            Économies annuelles
                            <app-tooltip text="Montant total économisé chaque année grâce à la production solaire, calculé en fonction de la consommation, de la production PV et du prix de l'électricité."></app-tooltip>
                          </div>
                          <div class="metric-value">{{ n(comprehensive?.financial?.annualSavings) | number:'1.0-0' }} <span class="metric-unit">DH/an</span></div>
                        </div>
                      </div>
                      <div class="metric-item">
                        <div class="metric-icon"></div>
                        <div class="metric-content">
                          <div class="metric-label">
                            ROI
                            <app-tooltip text="Retour sur Investissement : nombre d'années nécessaires pour récupérer le coût d'installation grâce aux économies réalisées. Calculé comme : Coût d'installation / Économies annuelles."></app-tooltip>
                          </div>
                          <div class="metric-value">{{ n(comprehensive?.financial?.roi) | number:'1.0-1' }} <span class="metric-unit">ans</span></div>
                        </div>
                      </div>
                      <div class="metric-item">
                        <div class="metric-icon"></div>
                        <div class="metric-content">
                          <div class="metric-label">
                            PV recommandé
                            <app-tooltip text="Puissance photovoltaïque recommandée en kilowatts-crête (kWc), calculée pour optimiser l'autonomie énergétique et les économies selon votre consommation."></app-tooltip>
                          </div>
                          <div class="metric-value">{{ pvPowerValue() | number:'1.0-2' }} <span class="metric-unit">kW</span></div>
                        </div>
                      </div>
                    </div>
                  </div>

                  <!-- Before/After Chart -->
                  <div class="card card-chart" *ngIf="beforeAfterChartData.labels?.length">
                    <h3 class="card-title">Comparaison Avant/Après</h3>
                    <div class="chart-container">
                      <canvas baseChart [data]="beforeAfterChartData" [options]="barOptions" [type]="'bar'"></canvas>
                    </div>
                  </div>
                </div>
              </ng-container>

              <!-- FINANCIAL TAB -->
              <ng-container *ngIf="activeTab === 'financial'">
                <div class="content-grid">
                  <div class="card">
                    <h3 class="card-title">Indicateurs Financiers</h3>
                    <div class="data-table">
                      <div class="table-row header">
                        <div class="table-cell">Métrique</div>
                        <div class="table-cell align-right">Valeur</div>
                      </div>
                      <div class="table-row">
                        <div class="table-cell">
                          Coût d'installation
                          <app-tooltip text="Coût total d'installation du système microgrid incluant les panneaux solaires, les batteries, l'onduleur et l'installation."></app-tooltip>
                        </div>
                        <div class="table-cell align-right value-highlight">{{ n(comprehensive?.financial?.installationCost) | number:'1.0-0' }} DH</div>
                      </div>
                      <div class="table-row">
                        <div class="table-cell">
                          Économies annuelles
                          <app-tooltip text="Montant total économisé chaque année grâce à la production solaire, calculé en fonction de la consommation, de la production PV et du prix de l'électricité."></app-tooltip>
                        </div>
                        <div class="table-cell align-right value-success">{{ n(comprehensive?.financial?.annualSavings) | number:'1.0-0' }} DH/an</div>
                      </div>
                      <div class="table-row">
                        <div class="table-cell">
                          ROI
                          <app-tooltip text="Retour sur Investissement : nombre d'années nécessaires pour récupérer le coût d'installation grâce aux économies réalisées."></app-tooltip>
                        </div>
                        <div class="table-cell align-right">{{ n(comprehensive?.financial?.roi) | number:'1.0-1' }} ans</div>
                      </div>
                      <div class="table-row">
                        <div class="table-cell">
                          IRR
                          <app-tooltip text="Taux de Rendement Interne : taux d'intérêt effectif qui rend la valeur actuelle nette du projet égale à zéro. Un IRR élevé indique un investissement rentable."></app-tooltip>
                        </div>
                        <div class="table-cell align-right">{{ n(comprehensive?.financial?.irr) | number:'1.0-1' }}%</div>
                      </div>
                    </div>
                  </div>

                  <div class="card card-chart" *ngIf="financialEvolutionData.labels?.length">
                    <h3 class="card-title">Évolution Financière (20 ans)</h3>
                    <div class="chart-container">
                      <canvas baseChart [data]="financialEvolutionData" [options]="lineOptions" [type]="'line'"></canvas>
                    </div>
                  </div>
                </div>
              </ng-container>

              <!-- ENVIRONMENTAL TAB -->
              <ng-container *ngIf="activeTab === 'environmental'">
                <div class="content-grid">
                  <div class="card">
                    <h3 class="card-title">Impact Environnemental</h3>
                    <div class="data-table">
                      <div class="table-row header">
                        <div class="table-cell">Métrique</div>
                        <div class="table-cell align-right">Valeur</div>
                      </div>
                      <div class="table-row">
                        <div class="table-cell">
                          Production PV annuelle
                          <app-tooltip text="Quantité totale d'électricité produite par les panneaux solaires sur une année complète, exprimée en kilowattheures (kWh)."></app-tooltip>
                        </div>
                        <div class="table-cell align-right value-highlight">{{ n(comprehensive?.environmental?.annualPvProduction) | number:'1.0-0' }} kWh/an</div>
                      </div>
                      <div class="table-row">
                        <div class="table-cell">
                          CO₂ évité
                          <app-tooltip text="Quantité de dioxyde de carbone évitée grâce à la production solaire, calculée en fonction de l'électricité produite et du facteur d'émission du réseau électrique."></app-tooltip>
                        </div>
                        <div class="table-cell align-right value-success">{{ n(comprehensive?.environmental?.co2Avoided) | number:'1.0-2' }} t/an</div>
                      </div>
                      <div class="table-row">
                        <div class="table-cell">
                          Équivalent arbres
                          <app-tooltip text="Nombre d'arbres qu'il faudrait planter pour absorber la même quantité de CO₂ que celle évitée par votre installation solaire."></app-tooltip>
                        </div>
                        <div class="table-cell align-right">{{ n(comprehensive?.environmental?.equivalentTrees) | number:'1.0-0' }} arbres</div>
                      </div>
                      <div class="table-row">
                        <div class="table-cell">
                          Équivalent voitures
                          <app-tooltip text="Nombre de voitures qu'il faudrait retirer de la circulation pour obtenir le même impact environnemental que votre installation solaire."></app-tooltip>
                        </div>
                        <div class="table-cell align-right">{{ n(comprehensive?.environmental?.equivalentCars) | number:'1.0-0' }} voitures</div>
                      </div>
                    </div>
                  </div>
                </div>
              </ng-container>

              <!-- TECHNICAL TAB -->
              <ng-container *ngIf="activeTab === 'technical'">
                <div class="content-grid">
                  <div class="card">
                    <h3 class="card-title">Spécifications Techniques</h3>
                    <div class="data-table">
                      <div class="table-row header">
                        <div class="table-cell">Paramètre</div>
                        <div class="table-cell align-right">Valeur recommandée</div>
                      </div>
                      <div class="table-row">
                        <div class="table-cell">
                          Puissance PV recommandée
                          <app-tooltip text="Puissance photovoltaïque optimale en kilowatts-crête (kWc) pour votre établissement, calculée selon votre consommation et vos objectifs d'autonomie."></app-tooltip>
                        </div>
                        <div class="table-cell align-right value-highlight">{{ pvPowerValue() | number:'1.0-2' }} kW</div>
                      </div>
                      <div class="table-row">
                        <div class="table-cell">
                          Capacité batterie recommandée
                          <app-tooltip text="Capacité de stockage d'énergie recommandée en kilowattheures (kWh) pour assurer l'autonomie énergétique, notamment pendant les périodes sans soleil."></app-tooltip>
                        </div>
                        <div class="table-cell align-right value-highlight">{{ batteryCapacityValue() | number:'1.0-2' }} kWh</div>
                      </div>
                      <div class="table-row">
                        <div class="table-cell">
                          Surface PV nécessaire
                          <app-tooltip text="Surface totale nécessaire pour installer les panneaux solaires, calculée en fonction de la puissance PV recommandée (environ 5 m² par kWc)."></app-tooltip>
                        </div>
                        <div class="table-cell align-right">{{ pvSurfaceValue() | number:'1.0-0' }} m²</div>
                      </div>
                      <div class="table-row">
                        <div class="table-cell">
                          Autonomie énergétique
                          <app-tooltip text="Pourcentage de la consommation énergétique totale couverte par la production solaire et le stockage. Une autonomie élevée réduit la dépendance au réseau électrique."></app-tooltip>
                        </div>
                        <div class="table-cell align-right value-success">{{ energyAutonomyValue() | number:'1.0-1' }}%</div>
                      </div>
                    </div>
                  </div>
                </div>
              </ng-container>

              <!-- COMPARISON TAB -->
              <ng-container *ngIf="activeTab === 'comparison'">
                <div class="content-grid">
                  <div class="card" *ngIf="comprehensive?.beforeAfter">
                    <h3 class="card-title">Comparatif Avant/Après</h3>
                    <div class="data-table">
                      <div class="table-row header">
                        <div class="table-cell">MÉTRIQUE</div>
                        <div class="table-cell align-center">{{ isNewEstablishment ? 'Sans microgrid' : 'AVANT' }}</div>
                        <div class="table-cell align-center">{{ isNewEstablishment ? 'Avec microgrid' : 'APRÈS' }}</div>
                      </div>
                      <div class="table-row">
                        <div class="table-cell">Facture mensuelle</div>
                        <div class="table-cell align-center">{{ n(comprehensive.beforeAfter.beforeMonthlyBill) | number:'1.0-0' }} DH</div>
                        <div class="table-cell align-center value-success">{{ n(comprehensive.beforeAfter.afterMonthlyBill) | number:'1.0-0' }} DH</div>
                      </div>
                      <div class="table-row">
                        <div class="table-cell">Facture annuelle</div>
                        <div class="table-cell align-center">{{ n(comprehensive.beforeAfter.beforeAnnualBill) | number:'1.0-0' }} DH</div>
                        <div class="table-cell align-center value-success">{{ n(comprehensive.beforeAfter.afterAnnualBill) | number:'1.0-0' }} DH</div>
                      </div>
                      <div class="table-row">
                        <div class="table-cell">Autonomie</div>
                        <div class="table-cell align-center">{{ n(comprehensive.beforeAfter.beforeAutonomy) | number:'1.0-1' }}%</div>
                        <div class="table-cell align-center value-success">{{ n(comprehensive.beforeAfter.afterAutonomy) | number:'1.0-1' }}%</div>
                      </div>
                    </div>
                  </div>

                  <div class="card">
                    <h3 class="card-title">Scénarios What-If</h3>
                    <p class="card-description">Explorez l'impact de différents changements sur vos résultats</p>
                    <div class="scenarios-grid">
                      <button class="scenario-card" (click)="runWhatIf('consumption', 1.2)">
                        <div class="scenario-icon" style="background: linear-gradient(135deg, #F59E0B, #F97316);"></div>
                        <div class="scenario-content">
                          <div class="scenario-title">+20% Consommation</div>
                          <div class="scenario-desc">Impact d'une augmentation de la consommation</div>
                        </div>
                        <div class="scenario-arrow">→</div>
                      </button>
                      <button class="scenario-card" (click)="runWhatIf('surface', 100)">
                        <div class="scenario-icon" style="background: linear-gradient(135deg, #F4C430, #FBBF24);"></div>
                        <div class="scenario-content">
                          <div class="scenario-title">+100 m² PV</div>
                          <div class="scenario-desc">Bénéfices d'une surface supplémentaire</div>
                        </div>
                        <div class="scenario-arrow">→</div>
                      </button>
                      <button class="scenario-card" (click)="runWhatIf('battery', 2.0)">
                        <div class="scenario-icon" style="background: linear-gradient(135deg, #8B5CF6, #A78BFA);"></div>
                        <div class="scenario-content">
                          <div class="scenario-title">×2 Capacité batterie</div>
                          <div class="scenario-desc">Impact d'un doublement de la batterie</div>
                        </div>
                        <div class="scenario-arrow">→</div>
                      </button>
                      <button class="scenario-card" (click)="runWhatIf('price', 1.2)">
                        <div class="scenario-icon" style="background: linear-gradient(135deg, #EF4444, #F87171);"></div>
                        <div class="scenario-content">
                          <div class="scenario-title">+20% Prix électricité</div>
                          <div class="scenario-desc">Anticipation d'une hausse tarifaire</div>
                        </div>
                        <div class="scenario-arrow">→</div>
                      </button>
                    </div>
                  </div>
                </div>
              </ng-container>

              <!-- ALERTS TAB -->
              <ng-container *ngIf="activeTab === 'alerts'">
                <div class="content-grid">
                  <div class="card">
                    <h3 class="card-title">Alertes et Recommandations</h3>
                    <div class="alerts-list">
                      <div class="alert-item" *ngFor="let a of alerts">
                        <div class="alert-icon"></div>
                        <div class="alert-content">
                          <div class="alert-title">{{ a.title }}</div>
                          <div class="alert-message">{{ a.message }}</div>
                        </div>
                      </div>
                      <div class="alert-item info" *ngIf="!alerts.length">
                        <div class="alert-icon"></div>
                        <div class="alert-content">
                          <div class="alert-title">Aucune alerte</div>
                          <div class="alert-message">Votre configuration est optimale.</div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </ng-container>

              <!-- AI TAB -->
              <ng-container *ngIf="activeTab === 'ai'">
                <div class="content-grid">
                  <div class="card" *ngIf="isNewEstablishment">
                    <div class="info-box">
                      <div class="info-icon"></div>
                      <div class="info-content">
                        <h4>Données IA non disponibles</h4>
                        <p>Les prédictions IA et la détection d'anomalies nécessitent un historique de consommation. Les données seront disponibles après quelques jours d'exploitation.</p>
                      </div>
                    </div>
                  </div>

                  <ng-container *ngIf="!isNewEstablishment">
                    <div class="card" *ngIf="!forecastData.labels?.length && !mlRecommendations?.recommendations?.length && !anomalies">
                      <div class="info-box">
                        <div class="info-icon"></div>
                        <div class="info-content">
                          <h4>Aucune donnée IA disponible</h4>
                          <p>Les données IA seront disponibles une fois que l'établissement aura accumulé suffisamment d'historique de consommation.</p>
                        </div>
                      </div>
                      <button class="btn-secondary" (click)="load()">Actualiser</button>
                    </div>

                    <div class="card card-chart" *ngIf="forecastData.labels?.length">
                      <h3 class="card-title">Prévisions (7 jours)</h3>
                      <p class="card-description">Prédictions de consommation et production PV basées sur l'analyse IA</p>
                      <div class="chart-container">
                        <canvas baseChart [data]="forecastData" [options]="lineOptions" [type]="'line'"></canvas>
                      </div>
                    </div>

                    <div class="card" *ngIf="mlRecommendations?.recommendations?.length">
                      <h3 class="card-title">Recommandations ML</h3>
                      <div class="recommendations-list">
                        <div class="recommendation-item" *ngFor="let r of mlRecList()">
                          <div class="rec-badge" [class.warning]="(r.type||'').toLowerCase().includes('warn')">
                            {{ ((r.type || 'info') + '').toUpperCase() }}
                          </div>
                          <div class="rec-message">{{ r.message }}</div>
                        </div>
                      </div>
                    </div>

                    <div class="card" *ngIf="anomalies">
                      <h3 class="card-title">Détection d'Anomalies (7 jours)</h3>
                      <p class="card-description">Une anomalie correspond à un comportement inhabituel détecté par l'IA dans vos données de consommation, production PV ou batterie.</p>
                      
                      <div class="metrics-grid">
                        <div class="metric-item">
                          
                          <div class="metric-content">
                            <div class="metric-label">Total anomalies</div>
                            <div class="metric-value">{{ anomalies.statistics.totalAnomalies }}</div>
                            <div class="metric-sublabel">sur 7 jours</div>
                          </div>
                        </div>
                        <div class="metric-item">
                          
                          <div class="metric-content">
                            <div class="metric-label">Gravité moyenne</div>
                            <div class="metric-value">{{ anomalies.statistics.averageAnomalyScore | number:'1.0-2' }}</div>
                            <div class="metric-sublabel">score d'anomalie</div>
                          </div>
                        </div>
                        <div class="metric-item">
                          
                          <div class="metric-content">
                            <div class="metric-label">Type le plus fréquent</div>
                            <div class="metric-value">{{ anomalyTypeLabel(anomalies.statistics.mostCommonAnomalyType) }}</div>
                            <div class="metric-sublabel">{{ anomalies.statistics.mostCommonAnomalyType }}</div>
                          </div>
                        </div>
                      </div>

                      <div class="anomalies-details">
                        <div class="details-section">
                          <h4>Répartition par type</h4>
                          <div class="data-table" *ngIf="anomalyBreakdown().length > 0">
                            <div class="table-row header">
                              <div class="table-cell">Type d'anomalie</div>
                              <div class="table-cell align-right">Nombre</div>
                            </div>
                            <div class="table-row" *ngFor="let it of anomalyBreakdown()">
                              <div class="table-cell">
                                <span class="anomaly-type-badge" [class]="'badge-' + it.key">{{ it.label }}</span>
                              </div>
                              <div class="table-cell align-right">
                                <span class="count-value">{{ it.count }}</span>
                              </div>
                            </div>
                          </div>
                          <div class="empty-state" *ngIf="anomalyBreakdown().length === 0">
                            <p>Aucune anomalie par type disponible.</p>
                          </div>
                        </div>

                        <div class="details-section">
                          <h4>Top 5 anomalies récentes</h4>
                          <div class="anomalies-list">
                            <div class="anomaly-item" *ngFor="let a of topAnomalies(); let i = index" [class.anomaly-high]="abs(a.anomalyScore) > 0.7" [class.anomaly-medium]="abs(a.anomalyScore) > 0.4 && abs(a.anomalyScore) <= 0.7" [class.anomaly-low]="abs(a.anomalyScore) <= 0.4">
                              <div class="anomaly-rank">#{{ i + 1 }}</div>
                              <div class="anomaly-content">
                                <div class="anomaly-header">
                                  <div class="anomaly-type-wrapper">
                                    <span class="anomaly-type-badge-small" [class]="'badge-' + getAnomalyTypeKey(a.anomalyType)">{{ anomalyTypeLabel(a.anomalyType) }}</span>
                                  </div>
                                  <div class="anomaly-score-badge" [class.score-high]="abs(a.anomalyScore) > 0.7" [class.score-medium]="abs(a.anomalyScore) > 0.4 && abs(a.anomalyScore) <= 0.7" [class.score-low]="abs(a.anomalyScore) <= 0.4">
                                    {{ a.anomalyScore | number:'1.0-2' }}
                                  </div>
                                </div>
                                <div class="anomaly-recommendation" *ngIf="a.recommendation">
                                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="display: inline-block; vertical-align: middle; margin-right: 4px;">
                                    <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path>
                                    <line x1="12" y1="8" x2="12" y2="12"></line>
                                    <line x1="12" y1="16" x2="12.01" y2="16"></line>
                                  </svg>
                                  {{ a.recommendation }}
                                </div>
                                <div class="anomaly-no-action" *ngIf="!a.recommendation">
                                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="display: inline-block; vertical-align: middle; margin-right: 4px;">
                                    <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                                    <polyline points="22 4 12 14.01 9 11.01"></polyline>
                                  </svg>
                                  Aucune action requise
                                </div>
                              </div>
                            </div>
                            <div class="empty-state" *ngIf="!topAnomalies().length">
                              <p>Aucune anomalie détaillée disponible.</p>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </ng-container>
                </div>
              </ng-container>
            </div>
          </ng-container>
        </main>
      </div>
    </div>

    <!-- Scenario Loading Modal -->
    <div class="modal-overlay" *ngIf="scenarioLoading">
      <div class="modal-backdrop"></div>
      <div class="modal-loading">
        <div class="loading-spinner"></div>
        <p>Calcul du scénario...</p>
      </div>
    </div>

    <!-- Scenario Results Modal -->
    <div class="modal-overlay" *ngIf="scenarioDialog">
      <div class="modal-backdrop" (click)="closeScenario()"></div>
      <div class="modal-dialog" (click)="$event.stopPropagation()">
        <div class="modal-header">
          <div class="modal-title-group">
            <h2 class="modal-title">Résultats du Scénario</h2>
            <p class="modal-subtitle">{{ scenarioDialog.scenarioDescription }}</p>
          </div>
          <button class="modal-close" (click)="closeScenario()">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="18" y1="6" x2="6" y2="18"></line>
              <line x1="6" y1="6" x2="18" y2="18"></line>
            </svg>
          </button>
        </div>
        <div class="modal-body">
          <div class="scenario-results">
            <div class="scenario-row" *ngFor="let row of scenarioDialog.rows">
              <div class="scenario-row-header">
                <div class="scenario-icon-small" [style.--c]="row.color">{{ row.icon }}</div>
                <div class="scenario-label">{{ row.label }}</div>
              </div>
              <div class="scenario-comparison">
                <div class="scenario-value-group">
                  <div class="scenario-value-label">Actuel</div>
                  <div class="scenario-value">{{ row.current }}</div>
                </div>
                <div class="scenario-arrow">→</div>
                <div class="scenario-value-group">
                  <div class="scenario-value-label">Scénario</div>
                  <div class="scenario-value scenario-value-new" [style.--c]="row.color">{{ row.scenario }}</div>
                </div>
              </div>
              <div class="scenario-change">
                <div class="change-badge" [class.positive]="row.isPositive" [class.negative]="!row.isPositive">
                  <span class="change-icon">{{ row.isPositive ? '↗' : '↘' }}</span>
                  <span>{{ row.changeText }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn-primary" (click)="closeScenario()">Fermer</button>
        </div>
      </div>
    </div>
  `,
  styles: [`
    /* Dashboard Layout */
    .dashboard-layout {
      display: flex;
      min-height: 100vh;
      background: #F9FAF7;
    }

    /* Sidebar */
    .dashboard-sidebar {
      width: 260px;
      background: #FFFFFF;
      border-right: 1px solid rgba(0, 0, 0, 0.08);
      display: flex;
      flex-direction: column;
      position: fixed;
      height: 100vh;
      left: 0;
      top: 0;
      z-index: 100;
    }

    .sidebar-header {
      padding: 24px 20px;
      border-bottom: 1px solid rgba(0, 0, 0, 0.06);
    }

    .sidebar-logo {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .logo-icon {
      width: 40px;
      height: 40px;
      border-radius: 10px;
      background: linear-gradient(135deg, #4EA8DE, #6BCF9D);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 20px;
      color: white;
    }

    .logo-text {
      display: flex;
      flex-direction: column;
    }

    .logo-title {
      font-weight: 700;
      font-size: 16px;
      color: #3A3A3A;
      line-height: 1.2;
    }

    .logo-subtitle {
      font-size: 12px;
      color: #6B7280;
      font-weight: 500;
    }

    .sidebar-nav {
      flex: 1;
      padding: 16px 12px;
      display: flex;
      flex-direction: column;
      gap: 4px;
    }

    .nav-item {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 12px 16px;
      border-radius: 10px;
      text-decoration: none;
      color: #6B7280;
      font-weight: 600;
      font-size: 14px;
      transition: all 0.2s ease;
      cursor: pointer;
    }

    .nav-item:hover {
      background: rgba(78, 168, 222, 0.08);
      color: #4EA8DE;
    }

    .nav-item.active {
      background: linear-gradient(135deg, rgba(78, 168, 222, 0.12), rgba(107, 207, 157, 0.08));
      color: #4EA8DE;
      border: 1px solid rgba(78, 168, 222, 0.2);
    }

    .nav-icon {
      font-size: 18px;
      width: 24px;
      text-align: center;
    }

    .nav-label {
      flex: 1;
    }

    .sidebar-footer {
      margin-top: auto;
      padding: 16px 12px;
      border-top: 1px solid rgba(0, 0, 0, 0.08);
    }

    .logout-btn {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 12px 16px;
      border-radius: 10px;
      text-decoration: none;
      color: #EF4444;
      font-weight: 600;
      font-size: 14px;
      transition: all 0.2s ease;
      cursor: pointer;
      background: transparent;
      border: none;
      width: 100%;
      text-align: left;
    }

    .logout-btn:hover {
      background: rgba(239, 68, 68, 0.08);
      color: #DC2626;
    }

    /* Main Content Area */
    .dashboard-main {
      flex: 1;
      margin-left: 260px;
      display: flex;
      flex-direction: column;
      min-height: 100vh;
    }

    /* Header */
    .dashboard-header {
      background: #FFFFFF;
      border-bottom: 1px solid rgba(0, 0, 0, 0.08);
      padding: 20px 32px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      position: sticky;
      top: 0;
      z-index: 50;
    }

    .header-left {
      display: flex;
      align-items: center;
      gap: 16px;
    }

    .header-back {
      width: 40px;
      height: 40px;
      border-radius: 10px;
      border: 1px solid rgba(0, 0, 0, 0.1);
      background: #FFFFFF;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      transition: all 0.2s ease;
      color: #6B7280;
    }

    .header-back:hover {
      background: rgba(78, 168, 222, 0.08);
      border-color: rgba(78, 168, 222, 0.3);
      color: #4EA8DE;
    }

    .header-title-group {
      display: flex;
      flex-direction: column;
      gap: 4px;
    }

    .header-title {
      font-size: 24px;
      font-weight: 700;
      color: #1F2937;
      margin: 0;
      line-height: 1.2;
    }

    .header-subtitle {
      font-size: 14px;
      color: #6B7280;
      margin: 0;
    }

    .header-actions {
      display: flex;
      gap: 12px;
    }

    .action-btn {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 10px 16px;
      border-radius: 10px;
      border: 1px solid rgba(0, 0, 0, 0.1);
      background: #FFFFFF;
      color: #6B7280;
      font-weight: 600;
      font-size: 14px;
      cursor: pointer;
      transition: all 0.2s ease;
    }

    .action-btn:hover {
      background: rgba(78, 168, 222, 0.08);
      border-color: rgba(78, 168, 222, 0.3);
      color: #4EA8DE;
    }

    .action-btn.active {
      background: linear-gradient(135deg, rgba(78, 168, 222, 0.12), rgba(107, 207, 157, 0.08));
      border-color: rgba(78, 168, 222, 0.3);
      color: #4EA8DE;
    }

    .action-btn.pause-btn {
      background: linear-gradient(135deg, rgba(78, 168, 222, 0.12), rgba(107, 207, 157, 0.08));
      border-color: rgba(78, 168, 222, 0.3);
      color: #4EA8DE;
    }

    .action-btn.pause-btn.paused {
      background: rgba(239, 68, 68, 0.08);
      border-color: rgba(239, 68, 68, 0.3);
      color: #EF4444;
    }

    .action-btn.pause-btn.paused:hover {
      background: rgba(239, 68, 68, 0.12);
      border-color: rgba(239, 68, 68, 0.4);
    }

    .action-btn svg {
      flex-shrink: 0;
    }

    /* Content Area */
    .dashboard-content {
      flex: 1;
      padding: 32px;
      max-width: 1400px;
      margin: 0 auto;
      width: 100%;
    }

    .content-loading,
    .content-error {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 400px;
      gap: 16px;
    }

    .loading-spinner {
      width: 48px;
      height: 48px;
      border: 4px solid rgba(78, 168, 222, 0.1);
      border-top-color: #4EA8DE;
      border-radius: 50%;
      animation: spin 0.8s linear infinite;
    }

    @keyframes spin {
      to { transform: rotate(360deg); }
    }

    .content-error {
      text-align: center;
    }

    .error-icon {
      font-size: 48px;
      margin-bottom: 8px;
    }

    .content-error h3 {
      font-size: 20px;
      color: #1F2937;
      margin: 0 0 8px;
    }

    .content-error p {
      color: #6B7280;
      margin: 0 0 16px;
    }

    /* Tabs */
    .content-tabs {
      display: flex;
      gap: 8px;
      margin-bottom: 24px;
      border-bottom: 2px solid rgba(0, 0, 0, 0.06);
      padding-bottom: 0;
      overflow-x: auto;
    }

    .tab-btn {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 12px 20px;
      border: none;
      background: transparent;
      color: #6B7280;
      font-weight: 600;
      font-size: 14px;
      cursor: pointer;
      border-bottom: 2px solid transparent;
      margin-bottom: -2px;
      transition: all 0.2s ease;
      white-space: nowrap;
    }

    .tab-btn:hover {
      color: #4EA8DE;
      background: rgba(78, 168, 222, 0.05);
    }

    .tab-btn.active {
      color: #4EA8DE;
      border-bottom-color: #4EA8DE;
      background: rgba(78, 168, 222, 0.05);
    }

    .tab-icon {
      font-size: 18px;
    }

    /* Tab Content */
    .tab-content {
      animation: fadeIn 0.3s ease;
    }

    @keyframes fadeIn {
      from { opacity: 0; transform: translateY(8px); }
      to { opacity: 1; transform: translateY(0); }
    }

    /* Content Grid */
    .content-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
      gap: 24px;
    }

    /* Cards */
    .card {
      background: #FFFFFF;
      border-radius: 16px;
      padding: 24px;
      border: 1px solid rgba(0, 0, 0, 0.06);
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
      transition: all 0.2s ease;
    }

    .card:hover {
      box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
    }

    .card-hero {
      grid-column: 1 / -1;
    }

    .card-chart {
      grid-column: 1 / -1;
    }

    .card-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 20px;
    }

    .card-title {
      font-size: 18px;
      font-weight: 700;
      color: #1F2937;
      margin: 0 0 16px;
    }

    .card-description {
      font-size: 14px;
      color: #6B7280;
      margin: 0 0 20px;
      line-height: 1.5;
    }

    .card-badge {
      padding: 6px 12px;
      border-radius: 8px;
      font-size: 12px;
      font-weight: 700;
    }

    .score-badge {
      background: linear-gradient(135deg, rgba(78, 168, 222, 0.12), rgba(107, 207, 157, 0.08));
      color: #4EA8DE;
      border: 1px solid rgba(78, 168, 222, 0.2);
    }

    /* Score Display */
    .score-display {
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      padding: 20px 0;
      gap: 16px;
    }

    .score-circle {
      position: relative;
      width: 160px;
      height: 160px;
    }

    .score-ring {
      width: 100%;
      height: 100%;
      transform: rotate(-90deg);
    }

    .score-value {
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      font-size: 48px;
      font-weight: 700;
      background: linear-gradient(135deg, #4EA8DE, #6BCF9D);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
    }
    .score-stars {
      display: flex;
      justify-content: center;
      align-items: center;
      gap: 12px;
      margin-top: 16px;
    }
    .star {
      width: 40px;
      height: 40px;
      color: rgba(78, 168, 222, 0.15);
      transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .star.filled {
      color: #FBBF24;
      filter: drop-shadow(0 2px 8px rgba(251, 191, 36, 0.5));
      animation: starPulse 0.8s ease backwards;
      transform: scale(1);
    }
    .star.filled:hover {
      transform: scale(1.15);
      filter: drop-shadow(0 4px 12px rgba(251, 191, 36, 0.7));
    }
    .star.half {
      position: relative;
    }
    .star.half::before {
      content: '';
      position: absolute;
      left: 0;
      top: 0;
      width: 50%;
      height: 100%;
      background: #FBBF24;
      clip-path: polygon(0 0, 50% 0, 50% 100%, 0 100%);
    }
    .star svg {
      width: 100%;
      height: 100%;
      transition: transform 0.3s ease;
    }
    .star.filled svg {
      animation: starRotate 0.6s ease backwards;
    }
    @keyframes starPulse {
      0% {
        transform: scale(0) rotate(-180deg);
        opacity: 0;
      }
      60% {
        transform: scale(1.3) rotate(10deg);
      }
      100% {
        transform: scale(1) rotate(0deg);
        opacity: 1;
      }
    }
    @keyframes starRotate {
      0% {
        transform: rotate(-180deg);
      }
      100% {
        transform: rotate(0deg);
      }
    }
    .star:nth-child(1) {
      animation-delay: 0.1s;
    }
    .star:nth-child(2) {
      animation-delay: 0.25s;
    }
    .star:nth-child(3) {
      animation-delay: 0.4s;
    }
    /* Metrics Grid */
    .metrics-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 16px;
    }

    .metric-item {
      display: flex;
      align-items: flex-start;
      gap: 12px;
      padding: 16px;
      border-radius: 12px;
      background: rgba(78, 168, 222, 0.04);
      border: 1px solid rgba(78, 168, 222, 0.1);
    }

    .metric-icon {
      font-size: 24px;
      flex-shrink: 0;
    }

    .metric-content {
      flex: 1;
      min-width: 0;
    }

    .metric-label {
      font-size: 12px;
      color: #6B7280;
      font-weight: 600;
      margin-bottom: 6px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }

    .metric-value {
      font-size: 24px;
      font-weight: 700;
      color: #1F2937;
      line-height: 1.2;
    }

    .metric-unit {
      font-size: 14px;
      font-weight: 600;
      color: #6B7280;
      margin-left: 4px;
    }

    .metric-sublabel {
      font-size: 11px;
      color: #9CA3AF;
      margin-top: 4px;
    }

    /* Data Table */
    .data-table {
      display: flex;
      flex-direction: column;
      border: 1px solid rgba(0, 0, 0, 0.08);
      border-radius: 12px;
      overflow: hidden;
    }

    .table-row {
      display: grid;
      grid-template-columns: 1.5fr 1fr 1fr;
      gap: 12px;
      padding: 14px 16px;
      border-bottom: 1px solid rgba(0, 0, 0, 0.06);
    }

    .table-row:last-child {
      border-bottom: none;
    }

    .table-row.header {
      background: rgba(78, 168, 222, 0.06);
      font-weight: 700;
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      color: #6B7280;
    }

    .table-row.header .table-cell {
      border: none;
    }

    .table-cell {
      display: flex;
      align-items: center;
      font-size: 14px;
      color: #1F2937;
    }

    .table-cell.align-right {
      justify-content: flex-end;
    }

    .table-cell.align-center {
      justify-content: center;
    }

    .value-highlight {
      font-weight: 700;
      color: #4EA8DE;
    }

    .value-success {
      font-weight: 700;
      color: #10B981;
    }

    /* Charts */
    .chart-container {
      height: 320px;
      position: relative;
    }

    /* Scenarios */
    .scenarios-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
      gap: 16px;
    }

    .scenario-card {
      display: flex;
      align-items: center;
      gap: 16px;
      padding: 20px;
      border-radius: 12px;
      border: 1.5px solid rgba(0, 0, 0, 0.1);
      background: #FFFFFF;
      cursor: pointer;
      transition: all 0.2s ease;
      text-align: left;
      width: 100%;
    }

    .scenario-card:hover {
      transform: translateY(-2px);
      box-shadow: 0 8px 24px rgba(0, 0, 0, 0.1);
      border-color: rgba(78, 168, 222, 0.3);
    }

    .scenario-icon {
      width: 56px;
      height: 56px;
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 28px;
      flex-shrink: 0;
    }

    .scenario-content {
      flex: 1;
      min-width: 0;
    }

    .scenario-title {
      font-size: 15px;
      font-weight: 700;
      color: #1F2937;
      margin-bottom: 4px;
    }

    .scenario-desc {
      font-size: 13px;
      color: #6B7280;
      line-height: 1.4;
    }

    .scenario-arrow {
      font-size: 20px;
      color: #9CA3AF;
      flex-shrink: 0;
    }

    /* Alerts */
    .alerts-list {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .alert-item {
      display: flex;
      gap: 16px;
      padding: 16px;
      border-radius: 12px;
      background: rgba(244, 196, 48, 0.08);
      border: 1px solid rgba(244, 196, 48, 0.2);
    }

    .alert-item.info {
      background: rgba(78, 168, 222, 0.08);
      border-color: rgba(78, 168, 222, 0.2);
    }

    .alert-icon {
      font-size: 24px;
      flex-shrink: 0;
    }

    .alert-content {
      flex: 1;
    }

    .alert-title {
      font-size: 15px;
      font-weight: 700;
      color: #1F2937;
      margin-bottom: 4px;
    }

    .alert-message {
      font-size: 14px;
      color: #6B7280;
      line-height: 1.5;
    }

    /* Recommendations */
    .recommendations-list {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .recommendation-item {
      display: flex;
      align-items: flex-start;
      gap: 12px;
      padding: 14px;
      border-radius: 10px;
      background: rgba(78, 168, 222, 0.04);
      border: 1px solid rgba(78, 168, 222, 0.1);
    }

    .rec-badge {
      padding: 6px 10px;
      border-radius: 6px;
      font-size: 11px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      flex-shrink: 0;
      background: rgba(78, 168, 222, 0.12);
      color: #0B4F73;
      border: 1px solid rgba(78, 168, 222, 0.2);
    }

    .rec-badge.warning {
      background: rgba(244, 196, 48, 0.18);
      color: #7C5B00;
      border-color: rgba(244, 196, 48, 0.4);
    }

    .rec-message {
      flex: 1;
      font-size: 14px;
      color: #1F2937;
      font-weight: 600;
      line-height: 1.5;
    }

    /* Anomalies Details */
    .anomalies-details {
      margin-top: 24px;
      display: flex;
      flex-direction: column;
      gap: 32px;
    }

    .details-section h4 {
      font-size: 16px;
      font-weight: 700;
      color: #1F2937;
      margin: 0 0 16px;
      padding-bottom: 8px;
      border-bottom: 2px solid rgba(78, 168, 222, 0.2);
    }

    .table-row.empty-row {
      opacity: 0.5;
    }

    .anomaly-type-badge {
      display: inline-block;
      padding: 4px 10px;
      border-radius: 6px;
      font-size: 13px;
      font-weight: 600;
      background: rgba(78, 168, 222, 0.1);
      color: #4EA8DE;
    }

    .anomaly-type-badge.badge-high-consumption {
      background: rgba(239, 68, 68, 0.1);
      color: #EF4444;
    }

    .anomaly-type-badge.badge-low-consumption {
      background: rgba(59, 130, 246, 0.1);
      color: #3B82F6;
    }

    .anomaly-type-badge.badge-pv-malfunction {
      background: rgba(245, 158, 11, 0.1);
      color: #F59E0B;
    }

    .anomaly-type-badge.badge-battery-low {
      background: rgba(139, 92, 246, 0.1);
      color: #8B5CF6;
    }

    .anomaly-type-badge.badge-pv-overproduction {
      background: rgba(107, 207, 157, 0.1);
      color: #6BCF9D;
    }

    .count-value {
      font-weight: 700;
      font-size: 15px;
      color: #1F2937;
    }

    .anomalies-list {
      display: flex;
      flex-direction: column;
      gap: 14px;
    }

    .anomaly-item {
      position: relative;
      padding: 16px;
      border-radius: 12px;
      background: #FFFFFF;
      border: 2px solid rgba(0, 0, 0, 0.08);
      transition: all 0.3s ease;
      display: flex;
      gap: 12px;
    }

    .anomaly-item:hover {
      border-color: rgba(78, 168, 222, 0.3);
      box-shadow: 0 2px 8px rgba(78, 168, 222, 0.15);
      transform: translateY(-1px);
    }

    .anomaly-item.anomaly-high {
      border-left: 4px solid #EF4444;
    }

    .anomaly-item.anomaly-medium {
      border-left: 4px solid #F59E0B;
    }

    .anomaly-item.anomaly-low {
      border-left: 4px solid #6BCF9D;
    }

    .anomaly-rank {
      flex-shrink: 0;
      width: 32px;
      height: 32px;
      display: flex;
      align-items: center;
      justify-content: center;
      background: linear-gradient(135deg, rgba(78, 168, 222, 0.1), rgba(107, 207, 157, 0.08));
      border-radius: 8px;
      font-weight: 700;
      font-size: 14px;
      color: #4EA8DE;
    }

    .anomaly-content {
      flex: 1;
      display: flex;
      flex-direction: column;
      gap: 8px;
    }

    .anomaly-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
      margin-bottom: 4px;
    }

    .anomaly-type-wrapper {
      flex: 1;
    }

    .anomaly-type-badge-small {
      display: inline-block;
      padding: 5px 12px;
      border-radius: 8px;
      font-size: 13px;
      font-weight: 700;
      background: rgba(78, 168, 222, 0.1);
      color: #4EA8DE;
    }

    .anomaly-type-badge-small.badge-high-consumption {
      background: rgba(239, 68, 68, 0.1);
      color: #EF4444;
    }

    .anomaly-type-badge-small.badge-low-consumption {
      background: rgba(59, 130, 246, 0.1);
      color: #3B82F6;
    }

    .anomaly-type-badge-small.badge-pv-malfunction {
      background: rgba(245, 158, 11, 0.1);
      color: #F59E0B;
    }

    .anomaly-type-badge-small.badge-battery-low {
      background: rgba(139, 92, 246, 0.1);
      color: #8B5CF6;
    }

    .anomaly-type-badge-small.badge-pv-overproduction {
      background: rgba(107, 207, 157, 0.1);
      color: #6BCF9D;
    }

    .anomaly-score-badge {
      flex-shrink: 0;
      padding: 6px 12px;
      border-radius: 8px;
      font-size: 13px;
      font-weight: 700;
      background: rgba(107, 207, 157, 0.1);
      color: #6BCF9D;
    }

    .anomaly-score-badge.score-high {
      background: rgba(239, 68, 68, 0.1);
      color: #EF4444;
    }

    .anomaly-score-badge.score-medium {
      background: rgba(245, 158, 11, 0.1);
      color: #F59E0B;
    }

    .anomaly-score-badge.score-low {
      background: rgba(107, 207, 157, 0.1);
      color: #6BCF9D;
    }

    .anomaly-datetime {
      font-size: 13px;
      color: #6B7280;
      display: flex;
      align-items: center;
      gap: 4px;
    }

    .anomaly-recommendation {
      font-size: 13px;
      color: #1F2937;
      line-height: 1.5;
      padding: 8px 12px;
      background: rgba(78, 168, 222, 0.05);
      border-radius: 6px;
      border-left: 3px solid #4EA8DE;
      display: flex;
      align-items: flex-start;
      gap: 6px;
    }

    .anomaly-no-action {
      font-size: 12px;
      color: #9CA3AF;
      display: flex;
      align-items: center;
      gap: 4px;
      font-style: italic;
    }

    .empty-state {
      padding: 32px 20px;
      text-align: center;
      color: #9CA3AF;
      font-size: 14px;
      background: rgba(0, 0, 0, 0.02);
      border-radius: 8px;
      border: 1px dashed rgba(0, 0, 0, 0.1);
    }

    .empty-state p {
      margin: 0;
    }

    /* Info Box */
    .info-box {
      display: flex;
      gap: 16px;
      padding: 20px;
      border-radius: 12px;
      background: rgba(78, 168, 222, 0.06);
      border: 1px solid rgba(78, 168, 222, 0.2);
    }

    .info-icon {
      font-size: 24px;
      flex-shrink: 0;
    }

    .info-content h4 {
      font-size: 16px;
      font-weight: 700;
      color: #1F2937;
      margin: 0 0 8px;
    }

    .info-content p {
      font-size: 14px;
      color: #6B7280;
      margin: 0;
      line-height: 1.5;
    }

    /* Buttons */
    .btn-primary {
      background: linear-gradient(135deg, #4EA8DE, #6BCF9D);
      color: #FFFFFF;
      border: none;
      padding: 12px 24px;
      border-radius: 10px;
      font-weight: 600;
      font-size: 14px;
      cursor: pointer;
      transition: all 0.2s ease;
    }

    .btn-primary:hover {
      transform: translateY(-1px);
      box-shadow: 0 4px 12px rgba(78, 168, 222, 0.3);
    }

    .btn-secondary {
      background: #FFFFFF;
      color: #4EA8DE;
      border: 1.5px solid #4EA8DE;
      padding: 10px 20px;
      border-radius: 10px;
      font-weight: 600;
      font-size: 14px;
      cursor: pointer;
      transition: all 0.2s ease;
      margin-top: 16px;
    }

    .btn-secondary:hover {
      background: rgba(78, 168, 222, 0.08);
    }

    /* Modal */
    .modal-overlay {
      position: fixed;
      inset: 0;
      z-index: 1000;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .modal-backdrop {
      position: absolute;
      inset: 0;
      background: rgba(0, 0, 0, 0.5);
      backdrop-filter: blur(4px);
    }

    .modal-loading {
      position: relative;
      background: #FFFFFF;
      border-radius: 16px;
      padding: 40px;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 16px;
      box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
    }

    .modal-dialog {
      position: relative;
      background: #FFFFFF;
      border-radius: 20px;
      width: min(700px, calc(100vw - 64px));
      max-height: calc(100vh - 64px);
      display: flex;
      flex-direction: column;
      box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
      overflow: hidden;
    }

    .modal-header {
      padding: 24px;
      border-bottom: 1px solid rgba(0, 0, 0, 0.08);
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 16px;
      background: linear-gradient(135deg, rgba(78, 168, 222, 0.08), rgba(107, 207, 157, 0.05));
    }

    .modal-title-group {
      flex: 1;
    }

    .modal-title {
      font-size: 20px;
      font-weight: 700;
      color: #1F2937;
      margin: 0 0 4px;
    }

    .modal-subtitle {
      font-size: 14px;
      color: #6B7280;
      margin: 0;
    }

    .modal-close {
      width: 36px;
      height: 36px;
      border-radius: 8px;
      border: 1px solid rgba(0, 0, 0, 0.1);
      background: #FFFFFF;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      transition: all 0.2s ease;
      color: #6B7280;
      flex-shrink: 0;
    }

    .modal-close:hover {
      background: rgba(239, 68, 68, 0.1);
      border-color: rgba(239, 68, 68, 0.3);
      color: #EF4444;
    }

    .modal-body {
      padding: 24px;
      overflow-y: auto;
      flex: 1;
    }

    .modal-footer {
      padding: 20px 24px;
      border-top: 1px solid rgba(0, 0, 0, 0.08);
      display: flex;
      justify-content: flex-end;
    }

    /* Scenario Results */
    .scenario-results {
      display: flex;
      flex-direction: column;
      gap: 16px;
    }

    .scenario-row {
      padding: 18px;
      border-radius: 12px;
      background: rgba(0, 0, 0, 0.02);
      border: 1px solid rgba(0, 0, 0, 0.08);
    }

    .scenario-row-header {
      display: flex;
      align-items: center;
      gap: 12px;
      margin-bottom: 16px;
    }

    .scenario-icon-small {
      --c: #4EA8DE;
      width: 32px;
      height: 32px;
      border-radius: 8px;
      display: flex;
      align-items: center;
      justify-content: center;
      background: color-mix(in srgb, var(--c) 18%, transparent);
      color: var(--c);
      font-size: 16px;
    }

    .scenario-label {
      font-size: 15px;
      font-weight: 700;
      color: #1F2937;
    }

    .scenario-comparison {
      display: flex;
      align-items: center;
      gap: 16px;
      margin-bottom: 12px;
    }

    .scenario-value-group {
      flex: 1;
    }

    .scenario-value-label {
      font-size: 12px;
      color: #9CA3AF;
      margin-bottom: 4px;
    }

    .scenario-value {
      font-size: 18px;
      font-weight: 700;
      color: #1F2937;
    }

    .scenario-value-new {
      color: var(--c);
    }

    .scenario-arrow {
      font-size: 20px;
      color: #9CA3AF;
      flex-shrink: 0;
    }

    .scenario-change {
      margin-top: 8px;
    }

    .change-badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 8px 12px;
      border-radius: 8px;
      font-size: 13px;
      font-weight: 700;
    }

    .change-badge.positive {
      background: rgba(16, 185, 129, 0.12);
      color: #047857;
    }

    .change-badge.negative {
      background: rgba(239, 68, 68, 0.12);
      color: #B91C1C;
    }

    .change-icon {
      font-size: 14px;
    }

    /* Responsive */
    @media (max-width: 1200px) {
      .content-grid {
        grid-template-columns: 1fr;
      }
      .card-hero,
      .card-chart {
        grid-column: 1;
      }
    }

    @media (max-width: 768px) {
      .dashboard-sidebar {
        transform: translateX(-100%);
        transition: transform 0.3s ease;
      }
      .dashboard-main {
        margin-left: 0;
      }
      .dashboard-header {
        padding: 16px 20px;
      }
      .dashboard-content {
        padding: 20px;
      }
      .scenarios-grid {
        grid-template-columns: 1fr;
      }
    }
  `]
})
export class MobileComprehensiveResultsComponent implements OnInit, OnDestroy {
  establishmentId: number | null = null;
  isLoading = true;
  errorMessage = '';

  activeTab: 'overview' | 'financial' | 'environmental' | 'technical' | 'comparison' | 'alerts' | 'ai' = 'overview';

  comprehensive: any = null;
  recommendations: EstablishmentRecommendations | null = null;
  establishment: Establishment | null = null;
  forecast: LongTermForecastResponse | null = null;
  mlRecommendations: MlRecommendationsResponse | null = null;
  anomalies: AnomalyGraphResponse | null = null;

  autoRefreshEnabled = true;
  private refreshTimer: any = null;

  alerts: Array<{ title: string; message: string }> = [];

  beforeAfterChartData: ChartData<'bar'> = { labels: [], datasets: [] };
  financialEvolutionData: ChartData<'line'> = { labels: [], datasets: [] };
  forecastData: ChartData<'line'> = { labels: [], datasets: [] };

  lineOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        display: true,
        position: 'top',
        labels: {
          boxWidth: 10,
          boxHeight: 10,
          usePointStyle: true,
          font: { size: 12 }
        }
      }
    },
    scales: {
      x: {
        grid: { display: false },
        ticks: { maxRotation: 0, autoSkip: true, font: { size: 11 } }
      },
      y: {
        beginAtZero: true,
        ticks: { precision: 0, font: { size: 11 } },
        grid: { color: 'rgba(0, 0, 0, 0.05)' }
      }
    }
  };

  barOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { display: false }
    },
    scales: {
      x: {
        grid: { display: false },
        ticks: { font: { size: 11 } }
      },
      y: {
        beginAtZero: true,
        ticks: { precision: 0, font: { size: 11 } },
        grid: { color: 'rgba(0, 0, 0, 0.05)' }
      }
    }
  };

  scenarioDialog: any = null;
  scenarioLoading = false;

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private dashboardService: DashboardService,
    private establishmentService: EstablishmentService,
    private ai: AiService,
    private authService: AuthService
  ) {}

  ngOnInit(): void {
    const id = this.route.snapshot.queryParamMap.get('establishmentId') || localStorage.getItem('selectedEstablishmentId');
    this.establishmentId = id ? parseInt(id) : null;
    this.load();
    this.startAutoRefresh();
  }

  n(value: any, fallback: number = 0): number {
    return value === null || value === undefined || Number.isNaN(value) ? fallback : Number(value);
  }

  mlRecList(): any[] {
    return (this.mlRecommendations?.recommendations ?? []) as any[];
  }

  energyAutonomyValue(): number {
    const rec: any = this.recommendations as any;
    const fromRec = this.n(this.recommendations?.estimatedEnergyAutonomy ?? rec?.energyAutonomy ?? rec?.estimatedEnergyAutonomy, NaN);
    if (!Number.isNaN(fromRec) && fromRec > 0) return fromRec;

    const fromBa = this.n(this.comprehensive?.beforeAfter?.afterAutonomy ?? this.comprehensive?.beforeAfter?.afterAutonomyPercentage, NaN);
    if (!Number.isNaN(fromBa)) return fromBa;

    const fromEnv = this.n(this.comprehensive?.environmental?.autonomyPercentage ?? this.comprehensive?.autonomyPercentage ?? this.comprehensive?.autonomy, NaN);
    if (!Number.isNaN(fromEnv)) return fromEnv;

    return 0;
  }

  private lastExistingCalc(): any | null {
    try {
      const raw = localStorage.getItem('mw_existing_last_calc');
      return raw ? JSON.parse(raw) : null;
    } catch {
      return null;
    }
  }

  pvPowerValue(): number {
    const rec: any = this.recommendations as any;
    const v = this.n(rec?.recommendedPvPowerKwc ?? rec?.recommendedPvPowerKwc ?? rec?.recommendedPvPower, NaN);
    if (!Number.isNaN(v) && v > 0) return v;
    const calc = this.lastExistingCalc();
    return this.n(calc?.recommendedPVPower, 0);
  }

  batteryCapacityValue(): number {
    const rec: any = this.recommendations as any;
    const v = this.n(rec?.recommendedBatteryCapacityKwh ?? rec?.recommendedBatteryCapacity, NaN);
    if (!Number.isNaN(v) && v > 0) return v;
    const calc = this.lastExistingCalc();
    return this.n(calc?.recommendedBatteryCapacity, 0);
  }

  pvSurfaceValue(): number {
    const rec: any = this.recommendations as any;
    const v = this.n(rec?.recommendedPvSurfaceM2 ?? rec?.recommendedPvSurface, NaN);
    if (!Number.isNaN(v) && v > 0) return v;
    const calc = this.lastExistingCalc();
    const pv = this.n(calc?.recommendedPVPower, 0);
    return pv > 0 ? pv * 5.0 : 0;
  }

  getStarsArray(): Array<{ filled: boolean; half: boolean }> {
    const score = this.n(this.comprehensive?.globalScore?.score, 0);
    const stars: Array<{ filled: boolean; half: boolean }> = [];
    
    // 0-30: 1 étoile
    // 31-60: 2 étoiles
    // 61-100: 3 étoiles
    if (score <= 30) {
      stars.push({ filled: true, half: false });
      stars.push({ filled: false, half: false });
      stars.push({ filled: false, half: false });
    } else if (score <= 60) {
      stars.push({ filled: true, half: false });
      stars.push({ filled: true, half: false });
      stars.push({ filled: false, half: false });
    } else {
      stars.push({ filled: true, half: false });
      stars.push({ filled: true, half: false });
      stars.push({ filled: true, half: false });
    }
    
    return stars;
  }

  getStarCount(): number {
    const score = this.n(this.comprehensive?.globalScore?.score, 0);
    if (score <= 30) return 1;
    if (score <= 60) return 2;
    return 3;
  }

  anomalyTypeLabel(type: string | null | undefined): string {
    const t = (type ?? '').toLowerCase().trim();
    if (!t) return 'Anomalie';
    if (t === 'high_consumption') return 'Surconsommation';
    if (t === 'low_consumption') return 'Sous-consommation';
    if (t === 'pv_malfunction') return 'Défaut PV (production anormale)';
    if (t === 'battery_low') return 'Batterie faible';
    if (t === 'pv_overproduction') return 'Surproduction PV';
    return t.replace(/_/g, ' ');
  }

  anomalyBreakdown(): Array<{ key: string; label: string; count: number }> {
    // Calculer depuis la liste réelle des anomalies
    const list: any[] = (this.anomalies as any)?.anomalies ?? [];
    const counts = new Map<string, number>();
    
    // Compter chaque type d'anomalie
    list.forEach(a => {
      const type = (a.anomalyType || 'unknown').toLowerCase();
      counts.set(type, (counts.get(type) || 0) + 1);
    });
    
    // Si pas d'anomalies dans la liste, utiliser les statistiques du backend
    if (list.length === 0) {
      const s: any = this.anomalies?.statistics ?? {};
      counts.set('high_consumption', this.n(s.highConsumptionAnomalies, 0));
      counts.set('low_consumption', this.n(s.lowConsumptionAnomalies, 0));
      counts.set('pv_malfunction', this.n(s.pvMalfunctionAnomalies, 0));
      counts.set('pv_overproduction', this.n(s.pvOverproductionAnomalies, 0));
      counts.set('battery_low', this.n(s.batteryLowAnomalies, 0));
    }
    
    const items = [
      { key: 'high_consumption', label: 'Surconsommation', count: counts.get('high_consumption') || 0 },
      { key: 'low_consumption', label: 'Sous-consommation', count: counts.get('low_consumption') || 0 },
      { key: 'pv_malfunction', label: 'Défaut PV', count: counts.get('pv_malfunction') || 0 },
      { key: 'pv_overproduction', label: 'Surproduction PV', count: counts.get('pv_overproduction') || 0 },
      { key: 'battery_low', label: 'Batterie faible', count: counts.get('battery_low') || 0 }
    ];
    
    // Trier par nombre décroissant et ne garder que ceux avec un count > 0
    return items
      .filter(item => item.count > 0)
      .sort((a, b) => b.count - a.count);
  }

  topAnomalies(): any[] {
    const list: any[] = (this.anomalies as any)?.anomalies ?? [];
    if (!list || list.length === 0) return [];
    
    // Trier par score décroissant, puis par date récente
    return [...list]
      .sort((a, b) => {
        const scoreA = Math.abs(this.n(a?.anomalyScore, 0));
        const scoreB = Math.abs(this.n(b?.anomalyScore, 0));
        if (scoreB !== scoreA) {
          return scoreB - scoreA; // Score absolu décroissant
        }
        // Si même score, trier par date récente
        const dateA = new Date(a.datetime || 0).getTime();
        const dateB = new Date(b.datetime || 0).getTime();
        return dateB - dateA;
      })
      .slice(0, 5);
  }

  getAnomalyTypeKey(type: string | null | undefined): string {
    if (!type) return 'unknown';
    return type.toLowerCase().replace(/_/g, '-');
  }

  abs(value: number | null | undefined): number {
    if (value === null || value === undefined) return 0;
    return Math.abs(value);
  }

  logout(): void {
    this.authService.logout();
  }

  formatAnomalyDate(dateStr: string | null | undefined): string {
    if (!dateStr) return 'Date inconnue';
    try {
      const date = new Date(dateStr);
      const now = new Date();
      const diffMs = now.getTime() - date.getTime();
      const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
      const diffDays = Math.floor(diffHours / 24);
      
      if (diffHours < 1) {
        const diffMins = Math.floor(diffMs / (1000 * 60));
        return `Il y a ${diffMins} min`;
      } else if (diffHours < 24) {
        return `Il y a ${diffHours} h`;
      } else if (diffDays === 1) {
        return 'Hier';
      } else if (diffDays < 7) {
        return `Il y a ${diffDays} jours`;
      } else {
        return date.toLocaleDateString('fr-FR', { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' });
      }
    } catch {
      return dateStr;
    }
  }

  ngOnDestroy(): void {
    if (this.refreshTimer) clearInterval(this.refreshTimer);
  }

  get isNewEstablishment(): boolean {
    return !!(this.establishment && (this.establishment as any)['monthlyConsumptionKwh'] == null && (this.establishment as any)['projectBudgetDh'] != null);
  }

  load(): void {
    if (!this.establishmentId) {
      this.isLoading = false;
      this.errorMessage = 'Aucun établissement sélectionné.';
      return;
    }
    this.isLoading = true;
    this.errorMessage = '';

    forkJoin({
      comprehensive: this.dashboardService.getComprehensiveResults(this.establishmentId),
      recommendations: this.establishmentService.getRecommendations(this.establishmentId).pipe(catchError(() => of(null))),
      establishment: this.establishmentService.getEstablishment(this.establishmentId).pipe(catchError(() => of(null))),
      forecast: this.ai.getForecast(this.establishmentId, 7).pipe(catchError(() => of(null))),
      ml: this.ai.getMlRecommendations(this.establishmentId).pipe(catchError(() => of(null))),
      anomalies: this.ai.getAnomalies(this.establishmentId, 7).pipe(catchError(() => of(null)))
    }).subscribe({
      next: (res) => {
        this.comprehensive = res.comprehensive;
        this.recommendations = res.recommendations as any;
        this.establishment = res.establishment as any;
        this.forecast = res.forecast as any;
        this.mlRecommendations = res.ml as any;
        this.anomalies = res.anomalies as any;

        localStorage.setItem('selectedEstablishmentId', String(this.establishmentId));
        this.buildCharts();
        this.buildAlerts();
        this.isLoading = false;
      },
      error: () => {
        this.errorMessage = 'Erreur lors du chargement des résultats complets.';
        this.isLoading = false;
      }
    });
  }

  setTab(tab: 'overview' | 'financial' | 'environmental' | 'technical' | 'comparison' | 'alerts' | 'ai'): void {
    this.activeTab = tab;
  }

  private startAutoRefresh(): void {
    if (this.refreshTimer) clearInterval(this.refreshTimer);
    if (!this.autoRefreshEnabled) return;
    this.refreshTimer = setInterval(() => {
      if (this.autoRefreshEnabled) this.load();
    }, 30000);
  }

  toggleAutoRefresh(): void {
    this.autoRefreshEnabled = !this.autoRefreshEnabled;
    this.startAutoRefresh();
  }

  getPauseButtonTitle(): string {
    return this.autoRefreshEnabled ? 'Mettre en pause l\'auto-refresh' : 'Reprendre l\'auto-refresh';
  }

  async exportPdf(): Promise<void> {
    console.log('exportPdf() appelé');
    
    if (!this.comprehensive) {
      console.error('comprehensive est null ou undefined');
      alert('Les données ne sont pas encore chargées. Veuillez patienter.');
      return;
    }
    
    // Si l'établissement n'est pas chargé, essayer de le charger
    if (!this.establishment && this.establishmentId) {
      console.log('Chargement de l\'établissement...');
      try {
        this.establishmentService.getEstablishment(this.establishmentId).subscribe({
          next: (est) => {
            if (est) {
              this.establishment = est as any;
              this.generatePdf();
            } else {
              // Si on ne peut pas charger l'établissement, utiliser les données disponibles
              this.generatePdfWithFallback();
            }
          },
          error: (err) => {
            console.error('Erreur lors du chargement de l\'établissement:', err);
            // Utiliser les données disponibles même sans établissement
            this.generatePdfWithFallback();
          }
        });
        return;
      } catch (error) {
        console.error('Erreur lors du chargement de l\'établissement:', error);
        this.generatePdfWithFallback();
        return;
      }
    }
    
    if (!this.establishment) {
      // Utiliser les données disponibles même sans établissement
      this.generatePdfWithFallback();
      return;
    }
    
    this.generatePdf();
  }

  private generatePdf(): void {
    if (!this.comprehensive) return;
    
    try {
      console.log('Création du document PDF complet...');
      
      const doc = new jsPDF();
      const pageWidth = doc.internal.pageSize.getWidth();
      const pageHeight = doc.internal.pageSize.getHeight();
      const margin = 20;
      let yPos = margin;
      
      // Couleurs du thème médical + solaire
      const medicalBlue = [78, 168, 222]; // #4EA8DE
      const solarGreen = [107, 207, 157]; // #6BCF9D
      
      // ========== PAGE DE COUVERTURE ==========
      // Header avec gradient (simulé avec deux rectangles)
      doc.setFillColor(medicalBlue[0], medicalBlue[1], medicalBlue[2]);
      doc.rect(0, 0, pageWidth, 60, 'F');
      doc.setFillColor(solarGreen[0], solarGreen[1], solarGreen[2]);
      doc.rect(0, 0, pageWidth / 2, 60, 'F');
      
      doc.setTextColor(255, 255, 255);
      doc.setFontSize(24);
      doc.setFont('helvetica', 'bold');
      doc.text('Hospital Microgrid', margin, 30);
      doc.setFontSize(16);
      doc.setFont('helvetica', 'normal');
      doc.text('Rapport Complet des Résultats', margin, 42);
      
      yPos = 80;
      doc.setTextColor(0, 0, 0);
      
      // Nom de l'établissement (en grand)
      const establishmentName = this.establishment?.name || `Établissement #${this.establishmentId || 'N/A'}`;
      doc.setFontSize(18);
      doc.setFont('helvetica', 'bold');
      doc.setTextColor(medicalBlue[0], medicalBlue[1], medicalBlue[2]);
      doc.text('Établissement:', margin, yPos);
      yPos += 8;
      doc.setFontSize(16);
      doc.setTextColor(0, 0, 0);
      doc.text(establishmentName, margin, yPos);
      yPos += 20;
      
      // Score Global (centré)
      doc.setFontSize(14);
      doc.setFont('helvetica', 'bold');
      doc.text('Score Global de Performance', pageWidth / 2, yPos, { align: 'center' });
      yPos += 12;
      doc.setFontSize(36);
      doc.setFont('helvetica', 'bold');
      doc.setTextColor(medicalBlue[0], medicalBlue[1], medicalBlue[2]);
      const score = this.n(this.comprehensive?.globalScore?.score).toFixed(1);
      doc.text(`${score}/100`, pageWidth / 2, yPos, { align: 'center' });
      yPos += 15;
      
      // Système d'étoiles (utiliser des astérisques pour compatibilité PDF)
      const starCount = this.getStarCount();
      let starText = '';
      for (let i = 0; i < 3; i++) {
        if (i < starCount) {
          starText += '*';
        } else {
          starText += '·';
        }
        if (i < 2) starText += '  ';
      }
      doc.setFontSize(20);
      doc.setTextColor(251, 191, 36); // Couleur or pour les étoiles
      doc.text(starText, pageWidth / 2, yPos, { align: 'center' });
      yPos += 20;
      
      // Date de génération
      doc.setFontSize(10);
      doc.setFont('helvetica', 'normal');
      doc.setTextColor(128, 128, 128);
      doc.text(`Généré le ${new Date().toLocaleDateString('fr-FR', { day: '2-digit', month: 'long', year: 'numeric' })}`, pageWidth / 2, pageHeight - 20, { align: 'center' });
      
      // ========== PAGE 1: VUE D'ENSEMBLE ==========
      doc.addPage();
      yPos = margin;
      this.addSectionHeader(doc, 'Vue d\'ensemble', medicalBlue, margin, yPos, pageWidth);
      yPos += 15;
      
      // Indicateurs Clés
      doc.setFontSize(12);
      doc.setFont('helvetica', 'bold');
      doc.setTextColor(0, 0, 0);
      doc.text('Indicateurs Clés', margin, yPos);
      yPos += 8;
      doc.setFontSize(10);
      doc.setFont('helvetica', 'normal');
      
      const keyMetrics = [
        ['Autonomie énergétique', `${this.energyAutonomyValue().toFixed(1)}%`],
        ['Économies annuelles', `${this.n(this.comprehensive?.financial?.annualSavings).toFixed(0)} DH/an`],
        ['ROI', `${this.n(this.comprehensive?.financial?.roi).toFixed(1)} ans`],
        ['PV recommandé', `${this.pvPowerValue().toFixed(2)} kW`],
        ['Capacité batterie recommandée', `${this.batteryCapacityValue().toFixed(2)} kWh`],
        ['Surface PV nécessaire', `${this.pvSurfaceValue().toFixed(0)} m²`]
      ];
      
      keyMetrics.forEach(([label, value]) => {
        if (yPos > pageHeight - 30) {
          doc.addPage();
          yPos = margin;
        }
        doc.text(`${label}:`, margin, yPos);
        doc.setFont('helvetica', 'bold');
        doc.setTextColor(medicalBlue[0], medicalBlue[1], medicalBlue[2]);
        doc.text(value, margin + 100, yPos);
        doc.setFont('helvetica', 'normal');
        doc.setTextColor(0, 0, 0);
        yPos += 7;
      });
      
      // ========== PAGE 2: FINANCIER ==========
      doc.addPage();
      yPos = margin;
      this.addSectionHeader(doc, 'Analyse Financière', medicalBlue, margin, yPos, pageWidth);
      yPos += 15;
      
      doc.setFontSize(10);
      doc.setFont('helvetica', 'normal');
      
      const financialMetrics = [
        ['Coût d\'installation', `${this.n(this.comprehensive?.financial?.installationCost).toFixed(0)} DH`],
        ['Économies annuelles', `${this.n(this.comprehensive?.financial?.annualSavings).toFixed(0)} DH/an`],
        ['ROI (Retour sur Investissement)', `${this.n(this.comprehensive?.financial?.roi).toFixed(1)} ans`],
        ['IRR (Taux de Rendement Interne)', `${this.n(this.comprehensive?.financial?.irr).toFixed(1)}%`],
        ['NPV (Valeur Actuelle Nette)', `${this.n((this.comprehensive?.financial as any)?.npv || 0).toFixed(0)} DH`]
      ];
      
      financialMetrics.forEach(([label, value]) => {
        if (yPos > pageHeight - 30) {
          doc.addPage();
          yPos = margin;
        }
        doc.text(`${label}:`, margin, yPos);
        doc.setFont('helvetica', 'bold');
        doc.setTextColor(solarGreen[0], solarGreen[1], solarGreen[2]);
        doc.text(value, margin + 100, yPos);
        doc.setFont('helvetica', 'normal');
        doc.setTextColor(0, 0, 0);
        yPos += 7;
      });
      
      // ========== PAGE 3: ENVIRONNEMENTAL ==========
      if (this.comprehensive?.environmental) {
        doc.addPage();
        yPos = margin;
        this.addSectionHeader(doc, 'Impact Environnemental', solarGreen, margin, yPos, pageWidth);
        yPos += 15;
        
        doc.setFontSize(10);
        doc.setFont('helvetica', 'normal');
        
        const envMetrics = [
          ['Production PV annuelle', `${this.n(this.comprehensive.environmental.annualPvProduction).toFixed(0)} kWh/an`],
          ['CO₂ évité', `${this.n(this.comprehensive.environmental.co2Avoided).toFixed(2)} t/an`],
          ['Équivalent arbres plantés', `${this.n(this.comprehensive.environmental.equivalentTrees).toFixed(0)} arbres`],
          ['Équivalent voitures retirées', `${this.n(this.comprehensive.environmental.equivalentCars).toFixed(0)} voitures`],
          ['Autonomie énergétique', `${this.n(this.comprehensive.environmental.autonomyPercentage).toFixed(1)}%`]
        ];
        
        envMetrics.forEach(([label, value]) => {
          if (yPos > pageHeight - 30) {
            doc.addPage();
            yPos = margin;
          }
          doc.text(`${label}:`, margin, yPos);
          doc.setFont('helvetica', 'bold');
          doc.setTextColor(solarGreen[0], solarGreen[1], solarGreen[2]);
          doc.text(value, margin + 100, yPos);
          doc.setFont('helvetica', 'normal');
          doc.setTextColor(0, 0, 0);
          yPos += 7;
        });
      }
      
      // ========== PAGE 4: TECHNIQUE ==========
      doc.addPage();
      yPos = margin;
      this.addSectionHeader(doc, 'Spécifications Techniques', medicalBlue, margin, yPos, pageWidth);
      yPos += 15;
      
      doc.setFontSize(10);
      doc.setFont('helvetica', 'normal');
      
      const techMetrics = [
        ['Puissance PV recommandée', `${this.pvPowerValue().toFixed(2)} kW`],
        ['Capacité batterie recommandée', `${this.batteryCapacityValue().toFixed(2)} kWh`],
        ['Surface PV nécessaire', `${this.pvSurfaceValue().toFixed(0)} m²`],
        ['Autonomie énergétique', `${this.energyAutonomyValue().toFixed(1)}%`]
      ];
      
      techMetrics.forEach(([label, value]) => {
        if (yPos > pageHeight - 30) {
          doc.addPage();
          yPos = margin;
        }
        doc.text(`${label}:`, margin, yPos);
        doc.setFont('helvetica', 'bold');
        doc.setTextColor(medicalBlue[0], medicalBlue[1], medicalBlue[2]);
        doc.text(value, margin + 100, yPos);
        doc.setFont('helvetica', 'normal');
        doc.setTextColor(0, 0, 0);
        yPos += 7;
      });
      
      // ========== PAGE 5: COMPARATIF AVANT/APRÈS ==========
      if (this.comprehensive?.beforeAfter) {
        doc.addPage();
        yPos = margin;
        this.addSectionHeader(doc, 'Comparatif Avant/Après Installation', solarGreen, margin, yPos, pageWidth);
        yPos += 15;
        
        doc.setFontSize(10);
        doc.setFont('helvetica', 'normal');
        
        const beforeAfter = [
          ['Facture mensuelle', 
            `${this.n(this.comprehensive.beforeAfter.beforeMonthlyBill).toFixed(0)} DH`, 
            `${this.n(this.comprehensive.beforeAfter.afterMonthlyBill).toFixed(0)} DH`],
          ['Facture annuelle', 
            `${this.n(this.comprehensive.beforeAfter.beforeAnnualBill).toFixed(0)} DH`, 
            `${this.n(this.comprehensive.beforeAfter.afterAnnualBill).toFixed(0)} DH`],
          ['Autonomie énergétique', 
            `${this.n(this.comprehensive.beforeAfter.beforeAutonomy).toFixed(1)}%`, 
            `${this.n(this.comprehensive.beforeAfter.afterAutonomy).toFixed(1)}%`]
        ];
        
        // En-tête du tableau
        doc.setFont('helvetica', 'bold');
        doc.text('Métrique', margin, yPos);
        doc.text('Avant', margin + 80, yPos);
        doc.text('Après', margin + 130, yPos);
        yPos += 8;
        doc.setDrawColor(200, 200, 200);
        doc.line(margin, yPos, pageWidth - margin, yPos);
        yPos += 5;
        
        beforeAfter.forEach(([label, before, after]) => {
          if (yPos > pageHeight - 30) {
            doc.addPage();
            yPos = margin;
          }
          doc.setFont('helvetica', 'normal');
          doc.text(label, margin, yPos);
          doc.text(before, margin + 80, yPos);
          doc.setFont('helvetica', 'bold');
          doc.setTextColor(solarGreen[0], solarGreen[1], solarGreen[2]);
          doc.text(after, margin + 130, yPos);
          doc.setTextColor(0, 0, 0);
          yPos += 7;
        });
      }
      
      // ========== PAGE 6: RECOMMANDATIONS ==========
      if (this.recommendations || this.mlRecommendations) {
        doc.addPage();
        yPos = margin;
        this.addSectionHeader(doc, 'Recommandations', medicalBlue, margin, yPos, pageWidth);
        yPos += 15;
        
        doc.setFontSize(10);
        doc.setFont('helvetica', 'normal');
        
        // Recommandations ML
        if (this.mlRecommendations?.recommendations?.length) {
          doc.setFont('helvetica', 'bold');
          doc.text('Recommandations Machine Learning:', margin, yPos);
          yPos += 8;
          doc.setFont('helvetica', 'normal');
          
          this.mlRecList().slice(0, 5).forEach((rec: any) => {
            if (yPos > pageHeight - 30) {
              doc.addPage();
              yPos = margin;
            }
            doc.text(`• ${rec.message || rec.recommendation || 'Recommandation'}`, margin + 5, yPos);
            yPos += 7;
          });
          yPos += 5;
        }
        
        // Recommandations générales
        if (this.recommendations) {
          doc.setFont('helvetica', 'bold');
          doc.text('Recommandations Générales:', margin, yPos);
          yPos += 8;
          doc.setFont('helvetica', 'normal');
          
          const recText = [
            `Puissance PV recommandée: ${this.pvPowerValue().toFixed(2)} kW`,
            `Capacité batterie recommandée: ${this.batteryCapacityValue().toFixed(2)} kWh`,
            `Surface nécessaire: ${this.pvSurfaceValue().toFixed(0)} m²`,
            `Autonomie attendue: ${this.energyAutonomyValue().toFixed(1)}%`
          ];
          
          recText.forEach(text => {
            if (yPos > pageHeight - 30) {
              doc.addPage();
              yPos = margin;
            }
            doc.text(`• ${text}`, margin + 5, yPos);
            yPos += 7;
          });
        }
      }
      
      // ========== FOOTER SUR TOUTES LES PAGES ==========
      const totalPages = doc.getNumberOfPages();
      for (let i = 1; i <= totalPages; i++) {
        doc.setPage(i);
        doc.setFontSize(9);
        doc.setTextColor(128, 128, 128);
        doc.text(
          `Page ${i} sur ${totalPages} - Hospital Microgrid System`,
          pageWidth / 2,
          pageHeight - 10,
          { align: 'center' }
        );
      }
      
      const fileName = `rapport_${establishmentName.replace(/[^a-zA-Z0-9]/g, '_')}_${new Date().getTime()}.pdf`;
      console.log('Sauvegarde du PDF:', fileName);
      doc.save(fileName);
      console.log('PDF exporté avec succès');
      
      alert('Rapport PDF exporté avec succès !');
    } catch (error) {
      console.error('Erreur détaillée lors de l\'export PDF:', error);
      console.error('Stack trace:', error instanceof Error ? error.stack : 'N/A');
      alert(`Erreur lors de l'export PDF: ${error instanceof Error ? error.message : 'Erreur inconnue'}. Veuillez vérifier la console pour plus de détails.`);
    }
  }

  private addSectionHeader(doc: jsPDF, title: string, color: number[], x: number, y: number, pageWidth: number): void {
    // En-tête de section avec couleur du thème (gradient médical + solaire)
    doc.setFillColor(color[0], color[1], color[2]);
    doc.roundedRect(x - 2, y - 8, pageWidth - 2 * (x - 2), 12, 3, 3, 'F');
    doc.setTextColor(255, 255, 255);
    doc.setFontSize(14);
    doc.setFont('helvetica', 'bold');
    doc.text(title, x + 2, y + 2);
    doc.setTextColor(0, 0, 0);
  }

  private generatePdfWithFallback(): void {
    // Utiliser la même fonction que generatePdf mais sans établissement
    this.generatePdf();
  }

  async shareText(): Promise<void> {
    if (!this.comprehensive) return;
    const globalScore = this.comprehensive?.globalScore?.score ?? 0;
    const autonomy = this.comprehensive?.environmental?.autonomyPercentage ?? this.comprehensive?.autonomy ?? 0;
    const annualSavings = this.comprehensive?.financial?.annualSavings ?? 0;
    const text =
      `Résultats Microgrid Solaire\n\n` +
      `Score Global: ${Number(globalScore).toFixed(1)}/100\n` +
      `Autonomie: ${Number(autonomy).toFixed(1)}%\n` +
      `Économies Annuelles: ${Number(annualSavings).toFixed(0)} DH/an\n`;

    try {
      await navigator.clipboard.writeText(text);
    } catch {
      const ta = document.createElement('textarea');
      ta.value = text;
      document.body.appendChild(ta);
      ta.select();
      document.execCommand('copy');
      document.body.removeChild(ta);
    }
  }

  private buildCharts(): void {
    const ba = this.comprehensive?.beforeAfter;
    if (ba) {
      const beforeLabel = this.isNewEstablishment ? 'Sans microgrid' : 'Avant';
      const afterLabel = this.isNewEstablishment ? 'Avec microgrid' : 'Après';
      this.beforeAfterChartData = {
        labels: [beforeLabel, afterLabel],
        datasets: [
          {
            data: [Number(ba.beforeMonthlyBill ?? 0), Number(ba.afterMonthlyBill ?? 0)],
            backgroundColor: ['rgba(231,76,60,0.75)', 'rgba(107,207,157,0.75)']
          }
        ]
      };
    } else {
      this.beforeAfterChartData = { labels: [], datasets: [] };
    }

    const annualSavings = Number(this.comprehensive?.financial?.annualSavings ?? 0);
    if (annualSavings > 0) {
      const labels = Array.from({ length: 20 }, (_, i) => `${i + 1}`);
      const data = labels.map((_, i) => annualSavings * (i + 1));
      this.financialEvolutionData = {
        labels,
        datasets: [
          {
            label: 'Économies cumulées (DH)',
            data,
            borderColor: '#4EA8DE',
            backgroundColor: 'rgba(78,168,222,0.18)',
            fill: true,
            tension: 0.35
          }
        ]
      };
    } else {
      this.financialEvolutionData = { labels: [], datasets: [] };
    }

    if (this.forecast?.predictions?.length) {
      const labels = this.forecast.predictions.map(p => `J${p.day}`);
      this.forecastData = {
        labels,
        datasets: [
          {
            label: 'Consommation',
            data: this.forecast.predictions.map(p => p.predictedConsumption),
            borderColor: '#4EA8DE',
            backgroundColor: 'rgba(78,168,222,0.12)',
            fill: true,
            tension: 0.35
          },
          {
            label: 'Production PV',
            data: this.forecast.predictions.map(p => p.predictedPvProduction),
            borderColor: '#F4C430',
            backgroundColor: 'rgba(244,196,48,0.10)',
            fill: true,
            tension: 0.35
          }
        ]
      };
    } else {
      this.forecastData = { labels: [], datasets: [] };
    }
  }

  private buildAlerts(): void {
    const autonomy = this.energyAutonomyValue();
    const roi = Number(this.comprehensive?.financial?.roi ?? 0);
    const alerts: Array<{ title: string; message: string }> = [];

    if (autonomy < 30) {
      alerts.push({
        title: 'Autonomie faible',
        message: "L'autonomie est inférieure à 30%. Recommandation: augmenter la surface PV."
      });
    }
    if (roi > 15) {
      alerts.push({
        title: 'ROI élevé',
        message: "Le retour sur investissement est supérieur à 15 ans. Optimisation recommandée."
      });
    }
    if (!alerts.length) {
      alerts.push({ title: 'Aucune alerte', message: 'Votre configuration est optimale.' });
    }
    this.alerts = alerts;
  }

  runWhatIf(type: 'consumption' | 'surface' | 'battery' | 'price', value: number): void {
    if (!this.comprehensive) return;
    this.scenarioLoading = true;
    setTimeout(() => {
      this.scenarioDialog = this.calculateScenarioResults(type, value);
      this.scenarioLoading = false;
    }, 250);
  }

  closeScenario(): void {
    this.scenarioDialog = null;
    this.scenarioLoading = false;
  }

  private calculateScenarioResults(type: string, value: number): any {
    const currentResults = this.comprehensive;
    const establishment = (this.establishment as any) ?? {};
    const beforeAfter = currentResults?.beforeAfter ?? {};
    const financial = currentResults?.financial ?? {};
    const rec: any = this.recommendations ?? {};
    const calc = this.lastExistingCalc() ?? {};

    const currentAutonomy = this.energyAutonomyValue();
    const currentAnnualSavings = Number(financial?.annualSavings ?? 0);
    const currentRoi = Number(financial?.roi ?? 0);
    const currentMonthlyBill = Number(beforeAfter?.afterMonthlyBill ?? 0);
    const currentAnnualBill = Number(beforeAfter?.afterAnnualBill ?? 0);
    const currentPvPower = this.pvPowerValue();
    const currentBatteryCapacity = this.batteryCapacityValue();
    const currentMonthlyConsumption = Number(establishment?.monthlyConsumptionKwh ?? calc?.monthlyConsumption ?? 50000.0);
    const currentElectricityPrice = 1.2;

    let newAutonomy = currentAutonomy;
    let newAnnualSavings = currentAnnualSavings;
    let newRoi = currentRoi;
    let newMonthlyBill = currentMonthlyBill;
    let newAnnualBill = currentAnnualBill;
    let newPvPower = currentPvPower;
    let newBatteryCapacity = currentBatteryCapacity;
    let newMonthlyConsumption = currentMonthlyConsumption;
    let newElectricityPrice = currentElectricityPrice;
    let scenarioDescription = '';

    switch (type) {
      case 'consumption':
        newMonthlyConsumption = currentMonthlyConsumption * value;
        scenarioDescription = `Consommation: ${currentMonthlyConsumption.toFixed(0)} → ${newMonthlyConsumption.toFixed(0)} kWh/mois`;
        newAutonomy = Math.max(0, Math.min(100, (currentAutonomy * currentMonthlyConsumption) / Math.max(newMonthlyConsumption, 1)));
        break;
      case 'surface': {
        const currentPvSurface = this.pvSurfaceValue();
        const newPvSurface = currentPvSurface + value;
        newPvPower = newPvSurface / 5.0;
        scenarioDescription = `Surface PV: ${currentPvSurface.toFixed(0)} → ${newPvSurface.toFixed(0)} m²`;
        newAutonomy = currentPvSurface > 0 ? Math.max(0, Math.min(100, (currentAutonomy * newPvSurface) / currentPvSurface)) : currentAutonomy;
        break;
      }
      case 'battery':
        newBatteryCapacity = currentBatteryCapacity * value;
        scenarioDescription = `Capacité batterie: ${currentBatteryCapacity.toFixed(0)} → ${newBatteryCapacity.toFixed(0)} kWh`;
        newAutonomy = Math.max(0, Math.min(100, currentAutonomy * 1.05));
        break;
      case 'price':
        newElectricityPrice = currentElectricityPrice * value;
        scenarioDescription = `Prix électricité: ${currentElectricityPrice.toFixed(2)} → ${newElectricityPrice.toFixed(2)} DH/kWh`;
        break;
    }

    const gridConsumption = newMonthlyConsumption * (1 - newAutonomy / 100.0);
    newMonthlyBill = gridConsumption * newElectricityPrice;
    newAnnualBill = newMonthlyBill * 12;

    const pvProduction = newMonthlyConsumption * (newAutonomy / 100.0);
    newAnnualSavings = pvProduction * 12 * newElectricityPrice;

    let installationCost = Number(financial?.installationCost ?? 0);
    if (type === 'surface') {
      const additionalCost = (newPvPower - currentPvPower) * 8000;
      installationCost += additionalCost;
    } else if (type === 'battery') {
      const additionalCost = (newBatteryCapacity - currentBatteryCapacity) * 4500;
      installationCost += additionalCost;
    }
    newRoi = newAnnualSavings > 0 ? installationCost / newAnnualSavings : newRoi;

    return {
      scenarioDescription,
      current: {
        autonomy: currentAutonomy,
        annualSavings: currentAnnualSavings,
        roi: currentRoi,
        monthlyBill: currentMonthlyBill,
        annualBill: currentAnnualBill
      },
      scenario: {
        autonomy: newAutonomy,
        annualSavings: newAnnualSavings,
        roi: newRoi,
        monthlyBill: newMonthlyBill,
        annualBill: newAnnualBill
      },
      changes: {
        autonomy: newAutonomy - currentAutonomy,
        annualSavings: newAnnualSavings - currentAnnualSavings,
        roi: newRoi - currentRoi,
        monthlyBill: newMonthlyBill - currentMonthlyBill,
        annualBill: newAnnualBill - currentAnnualBill
      },
      rows: this.buildScenarioRows({
        current: { autonomy: currentAutonomy, annualSavings: currentAnnualSavings, roi: currentRoi, monthlyBill: currentMonthlyBill, annualBill: currentAnnualBill },
        scenario: { autonomy: newAutonomy, annualSavings: newAnnualSavings, roi: newRoi, monthlyBill: newMonthlyBill, annualBill: newAnnualBill },
        changes: {
          autonomy: newAutonomy - currentAutonomy,
          annualSavings: newAnnualSavings - currentAnnualSavings,
          roi: newRoi - currentRoi,
          monthlyBill: newMonthlyBill - currentMonthlyBill,
          annualBill: newAnnualBill - currentAnnualBill
        }
      })
    };
  }

  private buildScenarioRows(payload: any): any[] {
    const c = payload.current;
    const s = payload.scenario;
    const d = payload.changes;

    const mk = (opts: {
      label: string;
      icon: string;
      color: string;
      current: string;
      scenario: string;
      change: number;
      isRoi?: boolean;
      isBill?: boolean;
      decimals?: number;
      suffix?: string;
    }) => {
      const isRoi = !!opts.isRoi;
      const isBill = !!opts.isBill;
      const isPositive = isRoi || isBill ? opts.change < 0 : opts.change > 0;
      const decimals = opts.decimals ?? (isRoi ? 1 : 0);
      const suffix = opts.suffix ?? (isRoi ? ' ans' : isBill ? ' DH' : '%');
      const abs = Math.abs(opts.change);
      const changeText = `${isPositive ? '+' : ''}${abs.toFixed(decimals)}${suffix}`;
      return { ...opts, isPositive, changeText };
    };

    return [
      mk({
        label: 'Autonomie énergétique',
        icon: '',
        color: '#22C55E',
        current: `${Number(c.autonomy).toFixed(1)}%`,
        scenario: `${Number(s.autonomy).toFixed(1)}%`,
        change: Number(d.autonomy),
        decimals: 1,
        suffix: '%'
      }),
      mk({
        label: 'Économies annuelles',
        icon: '',
        color: '#4EA8DE',
        current: `${Number(c.annualSavings).toFixed(0)} DH`,
        scenario: `${Number(s.annualSavings).toFixed(0)} DH`,
        change: Number(d.annualSavings),
        decimals: 0,
        suffix: ' DH'
      }),
      mk({
        label: 'ROI',
        icon: '',
        color: '#F4C430',
        current: `${Number(c.roi).toFixed(1)} ans`,
        scenario: `${Number(s.roi).toFixed(1)} ans`,
        change: Number(d.roi),
        isRoi: true,
        decimals: 1,
        suffix: ' ans'
      }),
      mk({
        label: 'Facture mensuelle',
        icon: '',
        color: '#F59E0B',
        current: `${Number(c.monthlyBill).toFixed(0)} DH`,
        scenario: `${Number(s.monthlyBill).toFixed(0)} DH`,
        change: Number(d.monthlyBill),
        isBill: true,
        decimals: 0,
        suffix: ' DH'
      }),
      mk({
        label: 'Facture annuelle',
        icon: '',
        color: '#EF4444',
        current: `${Number(c.annualBill).toFixed(0)} DH`,
        scenario: `${Number(s.annualBill).toFixed(0)} DH`,
        change: Number(d.annualBill),
        isBill: true,
        decimals: 0,
        suffix: ' DH'
      })
    ];
  }

  back(): void {
    this.router.navigate(['/establishments']);
  }
}
