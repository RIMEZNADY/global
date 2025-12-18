import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { EstablishmentService } from '../../services/establishment.service';
import { MobileDraftService } from '../../mobile-workflow/services/mobile-draft.service';
import { NavigationComponent } from '../../components/navigation/navigation.component';
import { TooltipComponent } from '../../components/tooltip/tooltip.component';

@Component({
  selector: 'app-web-form-b5',
  standalone: true,
  imports: [CommonModule, NavigationComponent, TooltipComponent],
  template: `
    <div class="web-form-container">
      <app-navigation></app-navigation>
      <div class="web-form-content">
        <div class="page-header">
          <h1>Décision Finale</h1>
          <p>NEW · Étape 5/5 · Création de l'établissement</p>
        </div>

        <div class="form-card">
          <div class="loading-card" *ngIf="isLoading">
            <div class="loading-spinner"></div>
            <p>Calcul des recommandations et création de l'établissement...</p>
          </div>

          <div class="error-card" *ngIf="errorMessage && !isLoading">
            <div class="error-icon">⚠️</div>
            <p class="error-text">{{ errorMessage }}</p>
            <button class="btn-retry" (click)="load()">Réessayer</button>
          </div>

          <div *ngIf="!isLoading && !errorMessage && calculations && economy">
            <div class="results-section">
              <h3>
                Prévisions Techniques
                <app-tooltip text="Les prévisions techniques basées sur votre configuration et les données du projet."></app-tooltip>
              </h3>
              
              <div class="metrics-grid">
                <div class="metric-card">
                  <div class="metric-label">Consommation annuelle prévue</div>
                  <div class="metric-value">{{ calculations.annualConsumption | number:'1.0-0' }} <span>kWh</span></div>
                </div>
                <div class="metric-card">
                  <div class="metric-label">Puissance PV requise</div>
                  <div class="metric-value">{{ calculations.requiredPVPower | number:'1.0-2' }} <span>kW</span></div>
                </div>
                <div class="metric-card">
                  <div class="metric-label">Surface PV nécessaire</div>
                  <div class="metric-value">{{ calculations.necessaryPVSurface | number:'1.0-0' }} <span>m²</span></div>
                </div>
                <div class="metric-card">
                  <div class="metric-label">Autonomie énergétique</div>
                  <div class="metric-value">{{ calculations.autonomyPercentage | number:'1.0-1' }} <span>%</span></div>
                </div>
                <div class="metric-card">
                  <div class="metric-label">Besoin batterie</div>
                  <div class="metric-value">{{ calculations.batteryNeed | number:'1.0-2' }} <span>kWh</span></div>
                </div>
              </div>
            </div>

            <div class="results-section">
              <h3>
                Économie Prévisionnelle
                <app-tooltip text="Les économies et retours sur investissement estimés pour votre projet."></app-tooltip>
              </h3>
              
              <div class="metrics-grid">
                <div class="metric-card economy">
                  <div class="metric-label">Coût d'installation (estim.)</div>
                  <div class="metric-value">{{ economy.installationCost | number:'1.0-0' }} <span>DH</span></div>
                </div>
                <div class="metric-card economy">
                  <div class="metric-label">Économie annuelle</div>
                  <div class="metric-value">{{ economy.annualSavings | number:'1.0-0' }} <span>DH</span></div>
                </div>
                <div class="metric-card economy">
                  <div class="metric-label">ROI</div>
                  <div class="metric-value">{{ economy.roi | number:'1.0-1' }} <span>ans</span></div>
                </div>
                <div class="metric-card economy">
                  <div class="metric-label">Réduction CO₂</div>
                  <div class="metric-value">{{ economy.co2Reduction | number:'1.0-2' }} <span>t/an</span></div>
                </div>
              </div>
            </div>

            <div class="form-actions">
              <button type="button" class="btn-secondary" (click)="back()">Retour</button>
              <button type="button" class="btn-primary" (click)="finish()" [disabled]="!establishmentId">
                Finaliser et voir les résultats
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  `,
  styleUrls: ['./web-form-b5.component.scss']
})
export class WebFormB5Component implements OnInit {
  isLoading = true;
  errorMessage = '';
  establishmentId: number | null = null;
  calculations: any = null;
  economy: any = null;

  constructor(
    private router: Router,
    private establishmentService: EstablishmentService,
    private draft: MobileDraftService
  ) {
    // Vérifier et nettoyer le token au démarrage
    const token = localStorage.getItem('auth_token');
    if (token) {
      // Nettoyer le token (enlever les espaces, retours à la ligne, etc.)
      const cleanToken = token.trim().replace(/\s+/g, '');
      if (cleanToken !== token) {
        localStorage.setItem('auth_token', cleanToken);
        console.log('Token cleaned and updated');
      }
    }
  }

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.isLoading = true;
    this.errorMessage = '';

    const b1 = this.draft.get<any>('b1');
    const b2 = this.draft.get<any>('b2_calc');
    const b3 = this.draft.get<any>('b3');
    
    // Vérification détaillée des données
    if (!b1) {
      this.isLoading = false;
      this.errorMessage = 'Données de localisation manquantes. Veuillez recommencer depuis l\'étape 1.';
      return;
    }
    
    if (!b2) {
      this.isLoading = false;
      this.errorMessage = 'Données du projet manquantes. Veuillez recommencer depuis l\'étape 2.';
      return;
    }
    
    if (!b3) {
      this.isLoading = false;
      this.errorMessage = 'Données d\'objectif manquantes. Veuillez recommencer depuis l\'étape 3.';
      return;
    }
    
    if (b1.lat == null || b1.lng == null) {
      this.isLoading = false;
      this.errorMessage = 'Localisation non définie. Veuillez sélectionner une localisation à l\'étape 1.';
      return;
    }

    if (!b3.type) {
      this.isLoading = false;
      this.errorMessage = 'Type d\'établissement non sélectionné. Veuillez compléter l\'étape 3.';
      return;
    }

    // Mapper la priorité française vers l'enum backend
    const mapPriorityToBackend = (priorite: string | null | undefined): string => {
      if (!priorite) return 'OPTIMIZE_ROI';
      if (priorite.includes('Haute') || priorite.includes('maximale')) {
        return 'MAXIMIZE_AUTONOMY';
      } else if (priorite.includes('Moyenne') || priorite.includes('Équilibre')) {
        return 'OPTIMIZE_ROI';
      } else if (priorite.includes('Basse') || priorite.includes('minimal')) {
        return 'MINIMIZE_COST';
      }
      return 'OPTIMIZE_ROI'; // Par défaut
    };

    const payload: any = {
      name: b3.type,
      type: b3.type,
      numberOfBeds: Math.round((b2.population || 0) / 100) || 1,
      latitude: b1.lat,
      longitude: b1.lng,
      irradiationClass: b1.irradiationClass || null,
      projectBudgetDh: b2.budget || 0,
      totalAvailableSurfaceM2: b2.totalSurface || 0,
      installableSurfaceM2: b2.solarSurface || 0,
      populationServed: b2.population || 0,
      projectPriority: mapPriorityToBackend(b3.priorite)
    };

    console.log('Creating establishment with payload:', payload);
    
    // Vérifier si un token existe
    const token = localStorage.getItem('auth_token');
    console.log('Token present:', !!token);
    if (token) {
      console.log('Token preview:', token.substring(0, 50) + '...');
    }

    this.establishmentService.createEstablishment(payload).subscribe({
      next: (created) => {
        console.log('Establishment created:', created);
        this.establishmentId = created.id;
        localStorage.setItem('selectedEstablishmentId', String(created.id));
        
        // Essayer de charger les recommandations et économies, mais rediriger vers les résultats même en cas d'erreur
        this.establishmentService.getRecommendations(created.id).subscribe({
          next: (rec) => {
            console.log('Recommendations loaded:', rec);
            this.establishmentService.getSavings(created.id, 1.2).subscribe({
              next: (sav) => {
                console.log('Savings loaded:', sav);
                this.calculations = {
                  annualConsumption: sav.annualConsumption,
                  requiredPVPower: rec.recommendedPvPowerKwc ?? rec['recommendedPvPower'] ?? 0,
                  necessaryPVSurface: rec.recommendedPvSurfaceM2 ?? rec['recommendedPvSurface'] ?? 0,
                  autonomyPercentage: rec.estimatedEnergyAutonomy ?? rec['energyAutonomy'] ?? 0,
                  batteryNeed: rec.recommendedBatteryCapacityKwh ?? rec['recommendedBatteryCapacity'] ?? 0
                };
                
                const installationCost = (b2.budget || 0) * 0.8;
                const annualPvProduction = sav.annualPvProduction ?? sav.annualPvEnergy ?? 0;
                const co2Reduction = (annualPvProduction * 0.5) / 1000;
                
                this.economy = {
                  installationCost,
                  annualSavings: sav.annualSavings,
                  roi: rec.estimatedROI ?? rec['roi'] ?? 0,
                  co2Reduction
                };
                
                this.isLoading = false;
                
                // Rediriger automatiquement vers les résultats complets après un délai plus long
                // pour permettre à l'utilisateur de voir les résultats préliminaires
                setTimeout(() => {
                  this.finish();
                }, 5000);
              },
              error: (err) => {
                console.error('Error loading savings:', err);
                // Même si les économies échouent, l'établissement est créé, on redirige vers les résultats
                this.isLoading = false;
                setTimeout(() => {
                  this.finish();
                }, 3000);
              }
            });
          },
          error: (err) => {
            console.error('Error loading recommendations:', err);
            // Même si les recommandations échouent, l'établissement est créé, on redirige vers les résultats
            this.isLoading = false;
            setTimeout(() => {
              this.finish();
            }, 3000);
          }
        });
      },
      error: (err) => {
        console.error('Error creating establishment:', err);
        console.error('Error details:', {
          status: err?.status,
          statusText: err?.statusText,
          message: err?.error?.message,
          error: err?.error
        });
        
        let errorMsg = 'Erreur lors de la création de l\'établissement.';
        
        if (err?.error?.message) {
          errorMsg = err.error.message;
        } else if (err?.status === 400) {
          errorMsg = 'Données invalides. Veuillez vérifier les informations saisies.';
        } else if (err?.status === 401) {
          errorMsg = 'Session expirée. Veuillez vous reconnecter et réessayer.';
        } else if (err?.status === 403) {
          errorMsg = 'Accès refusé. Vérifiez vos permissions ou reconnectez-vous.';
        } else if (err?.status === 500) {
          errorMsg = 'Erreur serveur. Veuillez réessayer plus tard.';
        } else if (err?.status === 0 || err?.status === undefined) {
          errorMsg = 'Impossible de contacter le serveur. Vérifiez votre connexion internet.';
        }
        
        this.errorMessage = errorMsg;
        this.isLoading = false;
      }
    });
  }

  finish(): void {
    if (!this.establishmentId) return;
    localStorage.setItem('selectedEstablishmentId', String(this.establishmentId));
    this.draft.clearAll();
    this.router.navigate(['/mobile/results/comprehensive'], { queryParams: { establishmentId: this.establishmentId } });
  }

  back(): void {
    this.router.navigate(['/web/b4']);
  }
}
