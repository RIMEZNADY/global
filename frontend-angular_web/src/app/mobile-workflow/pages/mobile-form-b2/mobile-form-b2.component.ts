import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { LocationService } from '../../../services/location.service';
import { MobileDraftService } from '../../services/mobile-draft.service';

@Component({
  selector: 'app-mobile-form-b2',
  template: `
    <div class="mw-page">
      <div class="mw-topbar">
        <button class="mw-back" (click)="back()">←</button>
        <div>
          <div class="mw-title">Informations du Projet</div>
          <div class="mw-sub">NEW · Étape 2/5</div>
        </div>
      </div>

      <div class="mw-content">
        <div class="mw-card" *ngIf="zoneLabel">
          <strong>Zone:</strong> {{ zoneLabel }}
          <span class="mw-muted">· valeurs auto-estimées basées sur la localisation</span>
        </div>

        <form class="mw-card" [formGroup]="form">
          <h2>Budget / Surfaces / Population</h2>

          <div class="mw-block">
            <div class="mw-block-head">
              <label>Budget global (DH)</label>
              <div class="mw-toggle">
                <span>Exact</span>
                <input type="checkbox" [checked]="useIntervalBudget" (change)="toggle('budget',$event)" />
                <span>Intervalle</span>
              </div>
              <button type="button" class="mw-mini" (click)="useEstimated('budget')">V.E</button>
            </div>
            <div *ngIf="!useIntervalBudget">
              <input type="number" formControlName="budget" placeholder="Ex: 2000000" />
            </div>
            <div class="mw-grid2" *ngIf="useIntervalBudget">
              <input type="number" formControlName="budgetMin" placeholder="Min" />
              <input type="number" formControlName="budgetMax" placeholder="Max" />
            </div>
          </div>

          <div class="mw-block">
            <div class="mw-block-head">
              <label>Surface totale (m²)</label>
              <div class="mw-toggle">
                <span>Exact</span>
                <input type="checkbox" [checked]="useIntervalTotalSurface" (change)="toggle('totalSurface',$event)" />
                <span>Intervalle</span>
              </div>
              <button type="button" class="mw-mini" (click)="useEstimated('totalSurface')">V.E</button>
            </div>
            <div *ngIf="!useIntervalTotalSurface">
              <input type="number" formControlName="totalSurface" placeholder="Ex: 5000" />
            </div>
            <div class="mw-grid2" *ngIf="useIntervalTotalSurface">
              <input type="number" formControlName="totalSurfaceMin" placeholder="Min" />
              <input type="number" formControlName="totalSurfaceMax" placeholder="Max" />
            </div>
          </div>

          <div class="mw-block">
            <div class="mw-block-head">
              <label>Surface non critique exploitable pour panneaux (m²)</label>
              <div class="mw-toggle">
                <span>Exact</span>
                <input type="checkbox" [checked]="useIntervalSolarSurface" (change)="toggle('solarSurface',$event)" />
                <span>Intervalle</span>
              </div>
            </div>
            <div *ngIf="!useIntervalSolarSurface">
              <input type="number" formControlName="solarSurface" placeholder="Ex: 2000" />
            </div>
            <div class="mw-grid2" *ngIf="useIntervalSolarSurface">
              <input type="number" formControlName="solarSurfaceMin" placeholder="Min" />
              <input type="number" formControlName="solarSurfaceMax" placeholder="Max" />
            </div>
          </div>

          <div class="mw-block">
            <div class="mw-block-head">
              <label>Population environnante</label>
              <div class="mw-toggle">
                <span>Exact</span>
                <input type="checkbox" [checked]="useIntervalPopulation" (change)="toggle('population',$event)" />
                <span>Intervalle</span>
              </div>
              <button type="button" class="mw-mini" (click)="useEstimated('population')" [disabled]="isEstimatingPop">
                {{ isEstimatingPop ? '...' : 'Estimer' }}
              </button>
            </div>
            <div *ngIf="!useIntervalPopulation">
              <input type="number" formControlName="population" placeholder="Ex: 50000" />
            </div>
            <div class="mw-grid2" *ngIf="useIntervalPopulation">
              <input type="number" formControlName="populationMin" placeholder="Min" />
              <input type="number" formControlName="populationMax" placeholder="Max" />
            </div>
            <div class="mw-muted" *ngIf="estimatedPopulation">
              Est: {{ estimatedPopulation | number:'1.0-0' }} habitants
            </div>
          </div>

          <div class="mw-error" *ngIf="errorMessage">{{ errorMessage }}</div>

          <div class="mw-footer">
            <button type="button" class="mw-btn" (click)="next()" [disabled]="form.invalid">Suivant</button>
          </div>
        </form>
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
      .mw-muted { font-size:12px; opacity:.75; }
      .mw-block { padding:12px; border-radius:14px; border:1px solid rgba(0,0,0,0.08); margin-bottom:12px; }
      .mw-block-head { display:flex; gap:10px; align-items:center; justify-content:space-between; margin-bottom:10px; flex-wrap:wrap; }
      .mw-block label { font-weight:800; font-size:13px; flex: 1 1 260px; }
      .mw-toggle { display:flex; align-items:center; gap:8px; font-size:12px; opacity:.8; }
      input { width:100%; padding:12px 12px; border-radius:12px; border:1px solid rgba(0,0,0,0.12); }
      .mw-grid2 { display:grid; grid-template-columns:1fr 1fr; gap:10px; }
      .mw-mini { padding:8px 10px; border-radius:10px; border:1px solid rgba(0,0,0,0.12); background:#fff; cursor:pointer; font-weight:800; }
      .mw-mini:disabled { opacity:.6; cursor:not-allowed; }
      .mw-footer { display:flex; justify-content:flex-end; }
      .mw-btn { padding:12px 18px; border-radius:14px; border:none; background: linear-gradient(135deg, var(--medical-blue), var(--solar-green)); color:#fff; font-weight:900; cursor:pointer; }
      .mw-btn:disabled { opacity:.6; cursor:not-allowed; }
      .mw-error { margin-top:12px; color: var(--error); font-size:13px; }
    `
  ]
})
export class MobileFormB2Component implements OnInit {
  form: FormGroup;
  useIntervalBudget = false;
  useIntervalTotalSurface = false;
  useIntervalSolarSurface = false;
  useIntervalPopulation = false;

  estimatedBudget: number | null = null;
  estimatedSurface: number | null = null;
  estimatedPopulation: number | null = null;
  isEstimatingPop = false;
  errorMessage = '';
  zoneLabel: string | null = null;

  constructor(
    private fb: FormBuilder,
    private router: Router,
    private locationService: LocationService,
    private draft: MobileDraftService
  ) {
    this.form = this.fb.group({
      budget: [null, [Validators.required, Validators.min(1)]],
      budgetMin: [null],
      budgetMax: [null],
      totalSurface: [null, [Validators.required, Validators.min(1)]],
      totalSurfaceMin: [null],
      totalSurfaceMax: [null],
      solarSurface: [null, [Validators.required, Validators.min(0)]],
      solarSurfaceMin: [null],
      solarSurfaceMax: [null],
      population: [null, [Validators.required, Validators.min(1)]],
      populationMin: [null],
      populationMax: [null]
    });
  }

  ngOnInit(): void {
    const b1 = this.draft.get<any>('b1');
    if (b1?.irradiationClass) this.zoneLabel = this.locationService.getZoneLabel(b1.irradiationClass);

    this.estimateValues();
    this.estimatePopulation();

    const saved = this.draft.get<any>('b2');
    if (saved) {
      this.useIntervalBudget = !!saved.useIntervalBudget;
      this.useIntervalTotalSurface = !!saved.useIntervalTotalSurface;
      this.useIntervalSolarSurface = !!saved.useIntervalSolarSurface;
      this.useIntervalPopulation = !!saved.useIntervalPopulation;
      this.form.patchValue(saved);
    }
    this.applyValidators();

    this.form.valueChanges.subscribe(v => {
      this.draft.set('b2', {
        ...v,
        useIntervalBudget: this.useIntervalBudget,
        useIntervalTotalSurface: this.useIntervalTotalSurface,
        useIntervalSolarSurface: this.useIntervalSolarSurface,
        useIntervalPopulation: this.useIntervalPopulation
      });
    });
  }

  private applyValidators(): void {
    // Helpers
    const reqMinMax = (minKey: string, maxKey: string, exactKey: string, min: number) => {
      if ((this as any)[`useInterval${exactKey}`]) {
        this.form.get(exactKey.toLowerCase())?.clearValidators();
      }
    };
    // Budget
    if (this.useIntervalBudget) {
      this.form.get('budget')?.clearValidators();
      this.form.get('budgetMin')?.setValidators([Validators.required, Validators.min(1)]);
      this.form.get('budgetMax')?.setValidators([Validators.required, Validators.min(1)]);
    } else {
      this.form.get('budget')?.setValidators([Validators.required, Validators.min(1)]);
      this.form.get('budgetMin')?.clearValidators();
      this.form.get('budgetMax')?.clearValidators();
    }
    // Total surface
    if (this.useIntervalTotalSurface) {
      this.form.get('totalSurface')?.clearValidators();
      this.form.get('totalSurfaceMin')?.setValidators([Validators.required, Validators.min(1)]);
      this.form.get('totalSurfaceMax')?.setValidators([Validators.required, Validators.min(1)]);
    } else {
      this.form.get('totalSurface')?.setValidators([Validators.required, Validators.min(1)]);
      this.form.get('totalSurfaceMin')?.clearValidators();
      this.form.get('totalSurfaceMax')?.clearValidators();
    }
    // Solar surface
    if (this.useIntervalSolarSurface) {
      this.form.get('solarSurface')?.clearValidators();
      this.form.get('solarSurfaceMin')?.setValidators([Validators.required, Validators.min(0)]);
      this.form.get('solarSurfaceMax')?.setValidators([Validators.required, Validators.min(0)]);
    } else {
      this.form.get('solarSurface')?.setValidators([Validators.required, Validators.min(0)]);
      this.form.get('solarSurfaceMin')?.clearValidators();
      this.form.get('solarSurfaceMax')?.clearValidators();
    }
    // Population
    if (this.useIntervalPopulation) {
      this.form.get('population')?.clearValidators();
      this.form.get('populationMin')?.setValidators([Validators.required, Validators.min(1)]);
      this.form.get('populationMax')?.setValidators([Validators.required, Validators.min(1)]);
    } else {
      this.form.get('population')?.setValidators([Validators.required, Validators.min(1)]);
      this.form.get('populationMin')?.clearValidators();
      this.form.get('populationMax')?.clearValidators();
    }
    Object.keys(this.form.controls).forEach(k => this.form.get(k)?.updateValueAndValidity({ emitEvent: false }));
  }

  toggle(kind: 'budget'|'totalSurface'|'solarSurface'|'population', e: Event): void {
    const v = (e.target as HTMLInputElement).checked;
    if (kind === 'budget') this.useIntervalBudget = v;
    if (kind === 'totalSurface') this.useIntervalTotalSurface = v;
    if (kind === 'solarSurface') this.useIntervalSolarSurface = v;
    if (kind === 'population') this.useIntervalPopulation = v;
    this.applyValidators();
  }

  private estimateValues(): void {
    const b1 = this.draft.get<any>('b1');
    const zone = b1?.irradiationClass as ('A'|'B'|'C'|'D'|null);
    const mult = zone === 'A' ? 1.2 : zone === 'B' ? 1.1 : zone === 'C' ? 1.0 : 0.9;
    this.estimatedBudget = Math.round(2000000 * mult);
    this.estimatedSurface = Math.round(5000 * mult);
  }

  estimatePopulation(): void {
    const b1 = this.draft.get<any>('b1');
    if (!b1?.lat || !b1?.lng) return;
    this.isEstimatingPop = true;
    this.locationService.estimatePopulation({ latitude: b1.lat, longitude: b1.lng }).subscribe({
      next: (n) => {
        this.estimatedPopulation = n;
        this.isEstimatingPop = false;
        if (!this.useIntervalPopulation && !this.form.value.population) {
          this.form.patchValue({ population: n }, { emitEvent: true });
        }
      },
      error: () => {
        this.isEstimatingPop = false;
        this.estimatedPopulation = null;
      }
    });
  }

  useEstimated(which: 'budget'|'totalSurface'|'population'): void {
    if (which === 'budget' && this.estimatedBudget != null) {
      this.form.patchValue({ budget: this.estimatedBudget });
    }
    if (which === 'totalSurface' && this.estimatedSurface != null) {
      this.form.patchValue({ totalSurface: this.estimatedSurface });
    }
    if (which === 'population') {
      if (this.estimatedPopulation != null) {
        if (this.useIntervalPopulation) {
          const min = Math.round(this.estimatedPopulation * 0.8);
          const max = Math.round(this.estimatedPopulation * 1.2);
          this.form.patchValue({ populationMin: min, populationMax: max });
        } else {
          this.form.patchValue({ population: this.estimatedPopulation });
        }
      } else {
        this.estimatePopulation();
      }
    }
  }

  private avg(min: number | null, max: number | null): number | null {
    if (min == null || max == null || min >= max) return null;
    return (min + max) / 2;
  }

  private getValue(useInterval: boolean, exact: number | null, min: number | null, max: number | null): number | null {
    if (!useInterval) return exact;
    return this.avg(min, max);
  }

  next(): void {
    this.errorMessage = '';
    this.form.markAllAsTouched();
    if (this.form.invalid) return;

    const budget = this.getValue(this.useIntervalBudget, this.form.value.budget, this.form.value.budgetMin, this.form.value.budgetMax);
    const totalSurface = this.getValue(this.useIntervalTotalSurface, this.form.value.totalSurface, this.form.value.totalSurfaceMin, this.form.value.totalSurfaceMax);
    const solarSurface = this.getValue(this.useIntervalSolarSurface, this.form.value.solarSurface, this.form.value.solarSurfaceMin, this.form.value.solarSurfaceMax);
    const population = this.getValue(this.useIntervalPopulation, this.form.value.population, this.form.value.populationMin, this.form.value.populationMax);
    if (budget == null || totalSurface == null || solarSurface == null || population == null) {
      this.errorMessage = 'Veuillez vérifier les intervalles (min < max) et les valeurs.';
      return;
    }

    this.draft.set('b2_calc', { budget, totalSurface, solarSurface, population: Math.round(population) });
    this.router.navigate(['/mobile/b3']);
  }

  back(): void {
    this.router.navigate(['/mobile/b1']);
  }
}

