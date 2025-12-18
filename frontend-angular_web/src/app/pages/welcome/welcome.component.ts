import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';

@Component({
  selector: 'app-welcome',
  template: `
    <div class="welcome-container">
      <div class="welcome-content">
        <div class="logo-container">
          <div class="solar-panel">
            <div class="panel-grid"></div>
            <div class="panel-icon">
              <span class="medical-icon">⚕</span>
              <span class="solar-icon">☀</span>
            </div>
          </div>
        </div>
        <h1 class="app-title gradient-text">SOLAR</h1>
        <h2 class="app-subtitle">MEDICAL</h2>
        <p class="app-tagline">Microgrid Intelligent pour Hôpitaux</p>
        <div class="loading-bar">
          <div class="loading-progress"></div>
        </div>
      </div>
    </div>
  `,
  styleUrls: ['./welcome.component.scss']
})
export class WelcomeComponent implements OnInit {
  constructor(private router: Router) {}

  ngOnInit(): void {
    setTimeout(() => {
      this.router.navigate(['/login']);
    }, 3000);
  }
}
