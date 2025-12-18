import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { MobileDraftService } from '../../services/mobile-draft.service';

@Component({
  selector: 'app-mobile-form-b4',
  template: `
    <div class="mw-page">
      <div class="mw-topbar">
        <button class="mw-back" (click)="back()">←</button>
        <div>
          <div class="mw-title">Recommandation</div>
          <div class="mw-sub">NEW · Étape 4/5</div>
        </div>
      </div>

      <div class="mw-content">
        <div class="mw-card">
          <h2>Score</h2>
          <div class="mw-score">
            <div class="mw-score-num">{{ score | number:'1.0-1' }}/100</div>
            <div class="mw-score-bar">
              <div class="mw-score-fill" [style.width.%]="score"></div>
            </div>
          </div>
          <div class="mw-muted">Type recommandé: {{ recommendedType }}</div>
          <button class="mw-mini" (click)="showDetails = !showDetails">Voir détails</button>
          <div class="mw-details" *ngIf="showDetails">
            <div>Surface solaire: {{ solarSurface | number:'1.0-0' }} m²</div>
            <div>Budget: {{ budget | number:'1.0-0' }} DH</div>
            <div>Population: {{ population | number:'1.0-0' }}</div>
          </div>
        </div>

        <div class="mw-footer">
          <button class="mw-btn" (click)="next()">Continuer</button>
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
      .mw-score { display:grid; gap:10px; }
      .mw-score-num { font-size:34px; font-weight:900; color: var(--medical-blue); }
      .mw-score-bar { height:10px; border-radius:999px; background: rgba(0,0,0,0.10); overflow:hidden; }
      .mw-score-fill { height:100%; background: linear-gradient(135deg, var(--medical-blue), var(--solar-green)); }
      .mw-muted { font-size:12px; opacity:.75; margin-top:8px; }
      .mw-mini { margin-top:10px; padding:8px 10px; border-radius:10px; border:1px solid rgba(0,0,0,0.12); background:#fff; cursor:pointer; font-weight:800; }
      .mw-details { margin-top:10px; padding:12px; border-radius:12px; background: rgba(78,168,222,0.06); border:1px solid rgba(78,168,222,0.18); font-size:13px; display:grid; gap:6px; }
      .mw-footer { display:flex; justify-content:flex-end; }
      .mw-btn { padding:12px 18px; border-radius:14px; border:none; background: linear-gradient(135deg, var(--medical-blue), var(--solar-green)); color:#fff; font-weight:900; cursor:pointer; }
    `
  ]
})
export class MobileFormB4Component implements OnInit {
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

    // Flutter-like scoring approximation
    let s = 70;
    if (this.solarSurface > 3000) s += 10;
    else if (this.solarSurface > 1500) s += 5;
    if (this.budget > 3000000) s += 10;
    else if (this.budget > 1500000) s += 5;
    this.score = Math.max(0, Math.min(100, s));

    this.draft.set('b4', { score: this.score });
  }

  next(): void {
    this.router.navigate(['/mobile/b5']);
  }

  back(): void {
    this.router.navigate(['/mobile/b3']);
  }
}

