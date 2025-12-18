import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { MobileDraftService } from '../../mobile-workflow/services/mobile-draft.service';
import { NavigationComponent } from '../../components/navigation/navigation.component';
import { TooltipComponent } from '../../components/tooltip/tooltip.component';

@Component({
  selector: 'app-web-form-b4',
  standalone: true,
  imports: [CommonModule, NavigationComponent, TooltipComponent],
  template: `
    <div class="web-form-container">
      <app-navigation></app-navigation>
      <div class="web-form-content">
        <div class="page-header">
          <h1>Score de Recommandation</h1>
          <p>NEW · Étape 4/5 · Évaluation de votre projet</p>
        </div>

        <div class="form-card">
          <div class="score-section">
            <h3>
              Score de faisabilité
              <app-tooltip text="Le score de faisabilité est calculé en fonction de votre budget, surface disponible, et zone d'irradiation. Un score élevé indique un projet très viable."></app-tooltip>
            </h3>
            
            <div class="score-display">
              <div class="score-circle">
                <div class="score-value">{{ score | number:'1.0-1' }}</div>
                <div class="score-max">/100</div>
              </div>
              <div class="score-bar-container">
                <div class="score-bar">
                  <div class="score-bar-fill" [style.width.%]="score"></div>
                </div>
                <p class="score-description">Type recommandé: {{ recommendedType }}</p>
              </div>
            </div>

            <button class="btn-details" (click)="showDetails = !showDetails">
              {{ showDetails ? 'Masquer' : 'Voir' }} les détails
            </button>

            <div class="details-card" *ngIf="showDetails">
              <h4>Détails du projet</h4>
              <div class="details-grid">
                <div class="detail-item">
                  <span class="detail-label">Surface solaire</span>
                  <span class="detail-value">{{ solarSurface | number:'1.0-0' }} m²</span>
                </div>
                <div class="detail-item">
                  <span class="detail-label">Budget</span>
                  <span class="detail-value">{{ budget | number:'1.0-0' }} DH</span>
                </div>
                <div class="detail-item">
                  <span class="detail-label">Population</span>
                  <span class="detail-value">{{ population | number:'1.0-0' }} habitants</span>
                </div>
              </div>
            </div>
          </div>

          <div class="form-actions">
            <button type="button" class="btn-secondary" (click)="back()">Retour</button>
            <button type="button" class="btn-primary" (click)="next()">Continuer</button>
          </div>
        </div>
      </div>
    </div>
  `,
  styleUrls: ['./web-form-b4.component.scss']
})
export class WebFormB4Component implements OnInit {
  score = 70;
  recommendedType = '';
  budget = 0;
  solarSurface = 0;
  population = 0;
  showDetails = false;

  constructor(private router: Router, private draft: MobileDraftService) {}

  ngOnInit(): void {
    const b2 = this.draft.get<any>('b2_calc');
    const b3 = this.draft.get<any>('b3');
    this.budget = b2?.budget ?? 0;
    this.solarSurface = b2?.solarSurface ?? 0;
    this.population = b2?.population ?? 0;
    this.recommendedType = b3?.type || '';

    // Calcul du score basé sur les critères
    let s = 70;
    if (this.solarSurface > 3000) s += 10;
    else if (this.solarSurface > 1500) s += 5;
    if (this.budget > 3000000) s += 10;
    else if (this.budget > 1500000) s += 5;
    this.score = Math.max(0, Math.min(100, s));

    this.draft.set('b4', { score: this.score });
  }

  next(): void {
    this.router.navigate(['/web/b5']);
  }

  back(): void {
    this.router.navigate(['/web/b3']);
  }
}

