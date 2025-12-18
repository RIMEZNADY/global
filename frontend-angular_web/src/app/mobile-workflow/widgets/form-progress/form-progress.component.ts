import { Component, Input } from '@angular/core';

@Component({
  selector: 'app-form-progress',
  template: `
    <div class="fp card">
      <div class="fp-bar">
        <div class="fp-bar-bg"></div>
        <div class="fp-bar-fill" [style.width.%]="progressPct"></div>
      </div>
      <div class="fp-meta">
        <span class="fp-pct">{{ progressPct | number : '1.0-0' }}%</span>
      </div>
      <div class="fp-steps">
        <div class="fp-step" *ngFor="let step of steps; let i = index">
          <div
            class="fp-circle"
            [class.fp-completed]="i + 1 < currentStep"
            [class.fp-current]="i + 1 === currentStep"
          >
            <span *ngIf="i + 1 < currentStep">✓</span>
            <span *ngIf="i + 1 >= currentStep">{{ i + 1 }}</span>
          </div>
          <div class="fp-label" *ngIf="labels?.[i]">{{ labels[i] }}</div>
        </div>
      </div>
    </div>
  `,
  styles: [
    `
      .fp {
        padding: 16px;
      }

      .fp-bar {
        position: relative;
        height: 6px;
        margin-bottom: 10px;
      }
      .fp-bar-bg {
        position: absolute;
        inset: 0;
        border-radius: 999px;
        background: rgba(0, 0, 0, 0.12);
      }
      .fp-bar-fill {
        position: absolute;
        inset: 0 auto 0 0;
        border-radius: 999px;
        background: linear-gradient(135deg, var(--medical-blue), var(--solar-green), var(--solar-yellow));
        box-shadow: 0 6px 12px rgba(37, 99, 235, 0.25);
        transition: width 250ms ease;
      }
      .fp-meta {
        display: flex;
        justify-content: flex-end;
      }
      .fp-pct {
        font-size: 12px;
        font-weight: 700;
        color: #2563eb;
      }
      .fp-steps {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(80px, 1fr));
        gap: 10px;
        margin-top: 14px;
      }
      .fp-step {
        text-align: center;
      }
      .fp-circle {
        width: 40px;
        height: 40px;
        border-radius: 50%;
        margin: 0 auto 6px;
        display: flex;
        align-items: center;
        justify-content: center;
        background: rgba(0, 0, 0, 0.12);
        color: rgba(58, 58, 58, 0.8);
        font-weight: 800;
        user-select: none;
      }
      .fp-circle.fp-current {
        background: linear-gradient(135deg, var(--medical-blue), var(--solar-yellow));
        color: #fff;
        border: 3px solid var(--medical-blue);
        box-shadow: 0 6px 12px rgba(37, 99, 235, 0.25);
      }
      .fp-circle.fp-completed {
        background: linear-gradient(135deg, #059669, #10b981);
        color: #fff;
        box-shadow: 0 6px 12px rgba(5, 150, 105, 0.25);
      }
      .fp-label {
        font-size: 11px;
        opacity: 0.75;
        line-height: 1.2;
      }
    `
  ]
})
export class FormProgressComponent {
  @Input() currentStep = 1;
  @Input() totalSteps = 3;
  @Input() labels: string[] = [];

  get steps(): number[] {
    return Array.from({ length: Math.max(1, this.totalSteps) }, (_, i) => i + 1);
  }

  get progressPct(): number {
    const denom = Math.max(1, this.totalSteps - 1);
    const progress = (this.currentStep - 1) / denom;
    return Math.max(0, Math.min(100, progress * 100));
  }
}

