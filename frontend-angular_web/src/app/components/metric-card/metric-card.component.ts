import { Component, Input } from '@angular/core';

@Component({
  selector: 'app-metric-card',
  template: `
    <div class="metric-card" [style.background]="gradient">
      <div class="metric-header">
        <span class="metric-icon">{{ icon }}</span>
        <span class="metric-change" [class.positive]="isPositive" [class.negative]="!isPositive">
          {{ change }}
        </span>
      </div>
      <div class="metric-value">{{ value }}</div>
      <div class="metric-label">{{ label }}</div>
    </div>
  `,
  styleUrls: ['./metric-card.component.scss']
})
export class MetricCardComponent {
  @Input() icon = '';
  @Input() label = '';
  @Input() value = '';
  @Input() change = '';
  @Input() gradientColors: string[] = ['#4EA8DE', '#6BCF9D'];

  get gradient(): string {
    return `linear-gradient(135deg, ${this.gradientColors[0]}, ${this.gradientColors[1]})`;
  }

  get isPositive(): boolean {
    return this.change.startsWith('+');
  }
}
