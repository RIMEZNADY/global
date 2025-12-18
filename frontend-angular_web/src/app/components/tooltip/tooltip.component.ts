import { Component, Input, ElementRef, ViewChild, AfterViewInit, HostListener } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-tooltip',
  imports: [CommonModule],
  template: `
    <div class="tooltip-wrapper" #wrapper>
      <span class="tooltip-icon" 
            (mouseenter)="onMouseEnter()" 
            (mouseleave)="onMouseLeave()"
            (focus)="onMouseEnter()"
            (blur)="onMouseLeave()"
            tabindex="0">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="12" cy="12" r="10"></circle>
          <line x1="12" y1="16" x2="12" y2="12"></line>
          <line x1="12" y1="8" x2="12.01" y2="8"></line>
        </svg>
      </span>
      <div class="tooltip-content" 
           #tooltipContent
           [class.show]="showTooltip && text && text.trim().length > 0"
           [class.position-top]="position === 'top'"
           [class.position-bottom]="position === 'bottom'"
           [class.position-left]="position === 'left'"
           [class.position-right]="position === 'right'"
           *ngIf="text && text.trim().length > 0">
        <div class="tooltip-arrow" [class.arrow-top]="position === 'top'" [class.arrow-bottom]="position === 'bottom'" [class.arrow-left]="position === 'left'" [class.arrow-right]="position === 'right'"></div>
        <div class="tooltip-text">{{ text }}</div>
      </div>
    </div>
  `,
  styles: [`
    .tooltip-wrapper {
      position: relative;
      display: inline-flex;
      align-items: center;
      margin-left: 6px;
    }

    .tooltip-icon {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      width: 18px;
      height: 18px;
      border-radius: 50%;
      background: rgba(78, 168, 222, 0.1);
      color: #4EA8DE;
      cursor: help;
      transition: all 0.2s ease;
      flex-shrink: 0;
    }

    .tooltip-icon:hover {
      background: rgba(78, 168, 222, 0.2);
      color: #0B4F73;
    }

    .tooltip-icon svg {
      width: 12px;
      height: 12px;
    }

    .tooltip-content {
      position: fixed;
      opacity: 0;
      pointer-events: none;
      transition: opacity 0.2s ease;
      z-index: 99999;
      min-width: 200px;
      max-width: 280px;
      visibility: hidden;
    }

    .tooltip-content.show {
      opacity: 1;
      pointer-events: auto;
      visibility: visible;
    }

    .tooltip-arrow {
      position: absolute;
      width: 0;
      height: 0;
    }

    .tooltip-arrow.arrow-top {
      bottom: -6px;
      left: 50%;
      transform: translateX(-50%);
      border-left: 6px solid transparent;
      border-right: 6px solid transparent;
      border-top: 6px solid #1F2937;
    }

    .tooltip-arrow.arrow-bottom {
      top: -6px;
      left: 50%;
      transform: translateX(-50%);
      border-left: 6px solid transparent;
      border-right: 6px solid transparent;
      border-bottom: 6px solid #1F2937;
    }

    .tooltip-arrow.arrow-left {
      right: -6px;
      top: 50%;
      transform: translateY(-50%);
      border-top: 6px solid transparent;
      border-bottom: 6px solid transparent;
      border-left: 6px solid #1F2937;
    }

    .tooltip-arrow.arrow-right {
      left: -6px;
      top: 50%;
      transform: translateY(-50%);
      border-top: 6px solid transparent;
      border-bottom: 6px solid transparent;
      border-right: 6px solid #1F2937;
    }

    .tooltip-text {
      background: #1F2937;
      color: #FFFFFF;
      padding: 8px 12px;
      border-radius: 6px;
      font-size: 11px;
      line-height: 1.4;
      box-shadow: 0 4px 16px rgba(0, 0, 0, 0.25);
      white-space: normal;
      word-wrap: break-word;
      overflow-wrap: break-word;
    }
  `],
  standalone: true
})
export class TooltipComponent implements AfterViewInit {
  @Input() text: string = '';
  @ViewChild('wrapper', { static: false }) wrapper!: ElementRef;
  @ViewChild('tooltipContent', { static: false }) tooltipContent!: ElementRef;
  
  showTooltip = false;
  position: 'top' | 'bottom' | 'left' | 'right' = 'top';

  ngAfterViewInit(): void {
    // Initialisation
  }

  @HostListener('window:scroll', ['$event'])
  @HostListener('window:resize', ['$event'])
  onScrollOrResize(): void {
    if (this.showTooltip) {
      this.updatePosition();
    }
  }

  onMouseEnter(): void {
    this.showTooltip = true;
    setTimeout(() => this.updatePosition(), 10);
  }

  onMouseLeave(): void {
    this.showTooltip = false;
  }

  private updatePosition(): void {
    if (!this.wrapper || !this.tooltipContent || !this.showTooltip) return;

    const wrapperEl = this.wrapper.nativeElement;
    const tooltipEl = this.tooltipContent.nativeElement;
    
    // Forcer le rendu pour obtenir les dimensions réelles
    tooltipEl.style.visibility = 'hidden';
    tooltipEl.style.display = 'block';
    
    const wrapperRect = wrapperEl.getBoundingClientRect();
    const tooltipRect = tooltipEl.getBoundingClientRect();
    const viewportWidth = window.innerWidth;
    const viewportHeight = window.innerHeight;
    
    const tooltipHeight = tooltipRect.height || 80;
    const tooltipWidth = tooltipRect.width || 250;
    const spacing = 12;
    
    // Calculer les espaces disponibles
    const spaceTop = wrapperRect.top;
    const spaceBottom = viewportHeight - wrapperRect.bottom;
    const spaceLeft = wrapperRect.left;
    const spaceRight = viewportWidth - wrapperRect.right;
    
    // Déterminer la meilleure position
    let bestPosition: 'top' | 'bottom' | 'left' | 'right' = 'top';
    
    if (spaceTop >= tooltipHeight + spacing) {
      bestPosition = 'top';
    } else if (spaceBottom >= tooltipHeight + spacing) {
      bestPosition = 'bottom';
    } else if (spaceRight >= tooltipWidth + spacing) {
      bestPosition = 'right';
    } else if (spaceLeft >= tooltipWidth + spacing) {
      bestPosition = 'left';
    } else {
      // Par défaut, essayer en bas
      bestPosition = spaceBottom > spaceTop ? 'bottom' : 'top';
    }
    
    this.position = bestPosition;
    
    // Calculer la position
    const iconCenterX = wrapperRect.left + wrapperRect.width / 2;
    const iconCenterY = wrapperRect.top + wrapperRect.height / 2;
    
    let top = 0;
    let left = 0;
    let transform = '';
    
    switch (this.position) {
      case 'top':
        top = wrapperRect.top - tooltipHeight - spacing;
        left = iconCenterX;
        transform = 'translateX(-50%)';
        break;
      case 'bottom':
        top = wrapperRect.bottom + spacing;
        left = iconCenterX;
        transform = 'translateX(-50%)';
        break;
      case 'left':
        top = iconCenterY;
        left = wrapperRect.left - tooltipWidth - spacing;
        transform = 'translateY(-50%)';
        break;
      case 'right':
        top = iconCenterY;
        left = wrapperRect.right + spacing;
        transform = 'translateY(-50%)';
        break;
    }
    
    // Ajuster si le tooltip dépasse de la fenêtre
    const margin = 10;
    if (left < margin) {
      left = margin;
      transform = '';
    } else if (left + tooltipWidth > viewportWidth - margin) {
      left = viewportWidth - tooltipWidth - margin;
      transform = '';
    }
    
    if (top < margin) {
      top = margin;
      if (this.position === 'left' || this.position === 'right') {
        transform = '';
      }
    } else if (top + tooltipHeight > viewportHeight - margin) {
      top = viewportHeight - tooltipHeight - margin;
      if (this.position === 'left' || this.position === 'right') {
        transform = '';
      }
    }
    
    tooltipEl.style.top = `${top}px`;
    tooltipEl.style.left = `${left}px`;
    tooltipEl.style.transform = transform;
    tooltipEl.style.visibility = 'visible';
  }
}
