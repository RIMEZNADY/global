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
          <select class="mw-select" [(ngModel)]="priorite">
            <option value="">Sélectionnez la priorité</option>
            <option *ngFor="let p of priorites" [value]="p">{{ p }}</option>
          </select>
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
      .mw-card h2 { font-size:18px; margin-bottom:10px; }
      .mw-select { width:100%; padding:12px 12px; border-radius:12px; border:1px solid rgba(0,0,0,0.12); }
      .mw-error { margin-top:12px; color: var(--error); font-size:13px; }
      .mw-footer { display:flex; justify-content:flex-end; }
      .mw-btn { padding:12px 18px; border-radius:14px; border:none; background: linear-gradient(135deg, var(--medical-blue), var(--solar-green)); color:#fff; font-weight:900; cursor:pointer; }
    `
  ]
})
export class MobileFormB3Component {
  type: string | null = null;
  priorite = '';
  errorMessage = '';
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
}
