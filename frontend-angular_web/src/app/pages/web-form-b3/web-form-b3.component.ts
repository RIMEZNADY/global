import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { MobileDraftService } from '../../mobile-workflow/services/mobile-draft.service';
import { NavigationComponent } from '../../components/navigation/navigation.component';
import { TooltipComponent } from '../../components/tooltip/tooltip.component';
import { HierarchicalTypeSelectorComponent } from '../../mobile-workflow/widgets/hierarchical-type-selector/hierarchical-type-selector.component';

@Component({
  selector: 'app-web-form-b3',
  standalone: true,
  imports: [CommonModule, FormsModule, NavigationComponent, TooltipComponent, HierarchicalTypeSelectorComponent],
  template: `
    <div class="web-form-container">
      <app-navigation></app-navigation>
      <div class="web-form-content">
        <div class="page-header">
          <h1>Objectif & Priorité</h1>
          <p>NEW · Étape 3/5 · Définissez les objectifs de votre projet</p>
        </div>

        <div class="form-card">
          <div class="form-section">
            <h3>
              Type d'établissement
              <app-tooltip text="Sélectionnez le type d'établissement de santé que vous souhaitez créer. Cette information influence les calculs et recommandations."></app-tooltip>
            </h3>
            <app-hierarchical-type-selector [value]="type" (valueChange)="type = $event"></app-hierarchical-type-selector>
          </div>

          <div class="form-section">
            <h3>
              Priorité du projet
              <app-tooltip text="Définissez la priorité principale de votre projet : maximiser la production d'énergie, équilibrer coût et efficacité, ou minimiser les coûts."></app-tooltip>
            </h3>
            
            <div class="form-group">
              <label class="form-label">Priorité</label>
              <div class="web-priority-dropdown">
                <button 
                  type="button" 
                  class="web-priority-trigger" 
                  (click)="priorityOpen = !priorityOpen"
                  [class.web-priority-selected]="priorite">
                  <span class="web-priority-text">{{ getPriorityLabel() || 'Sélectionnez la priorité' }}</span>
                  <span class="web-priority-caret" [class.web-priority-open]="priorityOpen">▾</span>
                </button>
                
                <div class="web-priority-backdrop" *ngIf="priorityOpen" (click)="priorityOpen = false"></div>
                <div class="web-priority-menu" *ngIf="priorityOpen">
                  <button 
                    type="button"
                    class="web-priority-option" 
                    *ngFor="let p of priorites"
                    (click)="selectPriority(p)"
                    [class.web-priority-active]="priorite === p">
                    <span class="web-priority-option-text">{{ p }}</span>
                    <span class="web-priority-option-check" *ngIf="priorite === p">✓</span>
                  </button>
                </div>
              </div>
            </div>

            <div class="error-message" *ngIf="errorMessage">
              <span>{{ errorMessage }}</span>
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
  styleUrls: ['./web-form-b3.component.scss']
})
export class WebFormB3Component {
  type: string | null = null;
  priorite = '';
  errorMessage = '';
  priorityOpen = false;
  priorites = [
    "Haute - Production maximale d'énergie",
    'Moyenne - Équilibre coût/efficacité',
    'Basse - Coût minimal'
  ];

  constructor(private router: Router, private draft: MobileDraftService) {
    const saved = this.draft.get<any>('b3');
    if (saved) {
      this.type = saved.type || null;
      this.priorite = saved.priorite || '';
    }
  }

  next(): void {
    this.errorMessage = '';
    if (!this.type || !this.priorite) {
      this.errorMessage = "Veuillez sélectionner le type d'établissement et la priorité.";
      return;
    }
    this.draft.set('b3', { type: this.type, priorite: this.priorite });
    this.router.navigate(['/web/b4']);
  }

  back(): void {
    this.router.navigate(['/web/b2']);
  }

  selectPriority(priority: string): void {
    this.priorite = priority;
    this.priorityOpen = false;
  }

  getPriorityLabel(): string {
    return this.priorite || '';
  }
}

