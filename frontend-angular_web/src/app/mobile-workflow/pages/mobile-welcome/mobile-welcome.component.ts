import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';

@Component({
  selector: 'app-mobile-welcome',
  template: `
    <div class="mw-container">
      <div class="mw-center">
        <div class="mw-logo">
          <span class="mw-icon"></span>
        </div>
        <h1 class="mw-title gradient-text">SOLAR MEDICAL</h1>
        <p class="mw-subtitle">Microgrid Intelligent pour Hôpitaux</p>

        <div class="mw-progress">
          <div class="mw-progress-bar"></div>
        </div>
      </div>
    </div>
  `,
  styles: [
    `
      .mw-container {
        min-height: 100vh;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 24px;
        background: linear-gradient(
          135deg,
          var(--off-white),
          rgba(78, 168, 222, 0.12),
          rgba(107, 207, 157, 0.08)
        );
      }

      .mw-center {
        text-align: center;
        max-width: 560px;
        width: 100%;
      }

      .mw-logo {
        width: 110px;
        height: 110px;
        margin: 0 auto 24px;
        border-radius: 26px;
        background: linear-gradient(135deg, var(--medical-blue), var(--solar-green));
        display: flex;
        align-items: center;
        justify-content: center;
        box-shadow: 0 14px 40px rgba(78, 168, 222, 0.35);
      }

      .mw-icon {
        font-size: 44px;
        color: #fff;
      }

      .mw-title {
        font-size: 40px;
        font-weight: 900;
        letter-spacing: 2px;
        margin-bottom: 10px;
      }

      .mw-subtitle {
        font-size: 14px;
        opacity: 0.75;
        margin-bottom: 40px;
      }

      .mw-progress {
        width: 240px;
        height: 3px;
        background: rgba(78, 168, 222, 0.12);
        border-radius: 999px;
        overflow: hidden;
        margin: 0 auto;
      }

      .mw-progress-bar {
        width: 50%;
        height: 100%;
        background: var(--medical-blue);
        animation: mwLoad 1.8s ease-in-out infinite;
      }

      @keyframes mwLoad {
        0% {
          transform: translateX(-120%);
        }
        50% {
          transform: translateX(60%);
        }
        100% {
          transform: translateX(240%);
        }
      }
    `
  ]
})
export class MobileWelcomeComponent implements OnInit {
  constructor(private router: Router) {}

  ngOnInit(): void {
    // Flutter welcome auto-navigates after ~5s
    setTimeout(() => this.router.navigate(['/mobile/auth']), 2500);
  }
}


