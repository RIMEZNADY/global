import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { MobileDraftService } from '../../services/mobile-draft.service';

@Component({
  selector: 'app-mobile-form-b3',
  template: `
    <div class="mw-page">
      <div class="mw-topbar">
        <button class="mw-back" (click)="back()">←</button>
        <div>
          <div class="mw-title">Objectif & Priorité</div>
          <div class="mw-sub">NEW · Étape 3/5</div>
        </div>
      </div>

      <div class="mw-content">
        <div class="mw-card">
          <h2>Objectif (type d’établissement)</h2>
          <app-hierarchical-type-selector [value]="type" (valueChange)="type = $event"></app-hierarchical-type-selector>
        </div>

        <div class="mw-card">
          <h2>Priorité</h2>
          <div class="mw-priority-dropdown">
            <button 
              type="button" 
              class="mw-priority-trigger" 
              (click)="priorityOpen = !priorityOpen"
              [class.mw-priority-selected]="priorite">
              <span class="mw-priority-text">{{ getPriorityLabel() || 'Sélectionnez la priorité' }}</span>
              <span class="mw-priority-caret" [class.mw-priority-open]="priorityOpen">▾</span>
            </button>
            
            <div class="mw-priority-backdrop" *ngIf="priorityOpen" (click)="priorityOpen = false"></div>
            <div class="mw-priority-menu" *ngIf="priorityOpen">
              <button 
                type="button"
                class="mw-priority-option" 
                *ngFor="let p of priorites"
                (click)="selectPriority(p)"
                [class.mw-priority-active]="priorite === p">
                <span class="mw-priority-option-text">{{ p }}</span>
                <span class="mw-priority-option-check" *ngIf="priorite === p">✓</span>
              </button>
            </div>
          </div>
          <div class="mw-error" *ngIf="errorMessage">{{ errorMessage }}</div>
        </div>

        <div class="mw-footer">
          <button class="mw-btn" (click)="next()">Suivant</button>
        </div>
      </div>
    </div>
  `,
  styles: [
    `
      .mw-page { min-height: 100vh; background: var(--off-white); }
      .mw-topbar { display:flex; gap:12px; align-items:center; padding:16px 18px; background:#fff; border-bottom:1px solid rgba(0,0,0,0.06); }
      .mw-back { width:44px; height:44px; border-radius:12px; border:1px solid rgba(0,0,0,0.08); background:#fff; cursor:pointer; font-size:18px; }
      .mw-title { font-weight:900; }
      .mw-sub { font-size:12px; opacity:.7; }
      .mw-content { max-width: 960px; margin:0 auto; padding:16px; display:grid; gap:16px; }
      .mw-card { background:#fff; border-radius:16px; padding:16px; border:1px solid rgba(0,0,0,0.06); box-shadow:0 6px 18px rgba(0,0,0,0.06); }
      .mw-card h2 { font-size:18px; margin-bottom:12px; font-weight:700; color: var(--soft-grey); }
      
      .mw-priority-dropdown {
        position: relative;
        width: 100%;
      }
      
      .mw-priority-trigger {
        width: 100%;
        display: flex;
        align-items: center;
        gap: 12px;
        padding: 14px 16px;
        border-radius: 12px;
        border: 2px solid rgba(78, 168, 222, 0.2);
        background: #fff;
        cursor: pointer;
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        text-align: left;
      }
      
      .mw-priority-trigger:hover {
        border-color: var(--medical-blue);
        box-shadow: 0 2px 8px rgba(78, 168, 222, 0.15);
      }
      
      .mw-priority-trigger.mw-priority-selected {
        border-color: var(--medical-blue);
        background: rgba(78, 168, 222, 0.05);
      }
      
      .mw-priority-icon {
        font-size: 18px;
        opacity: 0.8;
      }
      
      .mw-priority-text {
        flex: 1;
        font-size: 15px;
        font-weight: 500;
        color: var(--soft-grey);
      }
      
      .mw-priority-caret {
        font-size: 14px;
        color: var(--medical-blue);
        transition: transform 0.3s ease;
        opacity: 0.7;
      }
      
      .mw-priority-caret.mw-priority-open {
        transform: rotate(180deg);
      }
      
      .mw-priority-backdrop {
        position: fixed;
        inset: 0;
        background: rgba(0, 0, 0, 0.3);
        z-index: 999;
        backdrop-filter: blur(2px);
      }
      
      .mw-priority-menu {
        position: absolute;
        top: calc(100% + 8px);
        left: 0;
        right: 0;
        background: #fff;
        border-radius: 12px;
        border: 2px solid rgba(78, 168, 222, 0.2);
        box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
        z-index: 1000;
        overflow: hidden;
        animation: slideDown 0.2s ease;
      }
      
      @keyframes slideDown {
        from {
          opacity: 0;
          transform: translateY(-8px);
        }
        to {
          opacity: 1;
          transform: translateY(0);
        }
      }
      
      .mw-priority-option {
        width: 100%;
        display: flex;
        align-items: center;
        gap: 12px;
        padding: 14px 16px;
        border: none;
        background: transparent;
        cursor: pointer;
        text-align: left;
        transition: all 0.2s ease;
        border-bottom: 1px solid rgba(0, 0, 0, 0.05);
      }
      
      .mw-priority-option:last-child {
        border-bottom: none;
      }
      
      .mw-priority-option:hover {
        background: rgba(78, 168, 222, 0.08);
      }
      
      .mw-priority-option.mw-priority-active {
        background: linear-gradient(135deg, rgba(78, 168, 222, 0.1), rgba(107, 207, 157, 0.1));
        border-left: 3px solid var(--medical-blue);
      }
      
      .mw-priority-option-icon {
        font-size: 16px;
        opacity: 0.7;
      }
      
      .mw-priority-option-text {
        flex: 1;
        font-size: 15px;
        font-weight: 500;
        color: var(--soft-grey);
      }
      
      .mw-priority-option-check {
        color: var(--medical-blue);
        font-weight: 900;
        font-size: 16px;
      }
      .mw-error { margin-top:12px; color: var(--error); font-size:13px; font-weight:500; }
      .mw-footer { display:flex; justify-content:flex-end; }
      .mw-btn { padding:12px 18px; border-radius:14px; border:none; background: linear-gradient(135deg, var(--medical-blue), var(--solar-green)); color:#fff; font-weight:900; cursor:pointer; }
    `
  ]
})
export class MobileFormB3Component {
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
    this.router.navigate(['/mobile/b4']);
  }

  back(): void {
    this.router.navigate(['/mobile/b2']);
  }

  selectPriority(priority: string): void {
    this.priorite = priority;
    this.priorityOpen = false;
  }

  getPriorityLabel(): string {
    return this.priorite || '';
  }
}

