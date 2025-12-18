import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { WelcomeComponent } from './pages/welcome/welcome.component';
import { LoginComponent } from './pages/login/login.component';
import { RegisterComponent } from './pages/register/register.component';
import { InstitutionChoiceComponent } from './pages/institution-choice/institution-choice.component';
import { CreateEstablishmentComponent } from './pages/create-establishment/create-establishment.component';
import { EstablishmentsComponent } from './pages/establishments/establishments.component';
import { DashboardComponent } from './pages/dashboard/dashboard.component';
import { HomeComponent } from './pages/home/home.component';
import { AiPredictionComponent } from './pages/ai-prediction/ai-prediction.component';
import { AutoLearningComponent } from './pages/auto-learning/auto-learning.component';
import { AuthGuard } from './guards/auth.guard';
import { MobileWelcomeComponent } from './mobile-workflow/pages/mobile-welcome/mobile-welcome.component';
import { MobileAuthComponent } from './mobile-workflow/pages/mobile-auth/mobile-auth.component';
import { MobileInstitutionChoiceComponent } from './mobile-workflow/pages/mobile-institution-choice/mobile-institution-choice.component';
import { MobileMapSelectionComponent } from './mobile-workflow/pages/mobile-map-selection/mobile-map-selection.component';
import { MobileFormA1Component } from './mobile-workflow/pages/mobile-form-a1/mobile-form-a1.component';
import { MobileFormA2Component } from './mobile-workflow/pages/mobile-form-a2/mobile-form-a2.component';
import { MobileFormA3Component } from './mobile-workflow/pages/mobile-form-a3/mobile-form-a3.component';
import { MobileFormA4Component } from './mobile-workflow/pages/mobile-form-a4/mobile-form-a4.component';
import { MobileFormA5Component } from './mobile-workflow/pages/mobile-form-a5/mobile-form-a5.component';
import { MobileFormB1Component } from './mobile-workflow/pages/mobile-form-b1/mobile-form-b1.component';
import { MobileFormB2Component } from './mobile-workflow/pages/mobile-form-b2/mobile-form-b2.component';
import { MobileFormB3Component } from './mobile-workflow/pages/mobile-form-b3/mobile-form-b3.component';
import { MobileFormB4Component } from './mobile-workflow/pages/mobile-form-b4/mobile-form-b4.component';
import { MobileFormB5Component } from './mobile-workflow/pages/mobile-form-b5/mobile-form-b5.component';
import { MobileReviewComponent } from './mobile-workflow/pages/mobile-review/mobile-review.component';
import { MobileResultChoiceComponent } from './mobile-workflow/pages/mobile-result-choice/mobile-result-choice.component';
import { MobileCalculationResultsComponent } from './mobile-workflow/pages/mobile-calculation-results/mobile-calculation-results.component';
import { MobileComprehensiveResultsComponent } from './mobile-workflow/pages/mobile-comprehensive-results/mobile-comprehensive-results.component';
import { ProfileComponent } from './pages/profile/profile.component';
import { WebFormB1Component } from './pages/web-form-b1/web-form-b1.component';
import { WebFormB2Component } from './pages/web-form-b2/web-form-b2.component';
import { WebFormB3Component } from './pages/web-form-b3/web-form-b3.component';
import { WebFormB4Component } from './pages/web-form-b4/web-form-b4.component';
import { WebFormB5Component } from './pages/web-form-b5/web-form-b5.component';

const routes: Routes = [
  { path: '', redirectTo: '/welcome', pathMatch: 'full' },
  { path: 'welcome', component: WelcomeComponent },
  { path: 'login', component: LoginComponent },
  { path: 'register', component: RegisterComponent },
  { path: 'institution-choice', component: InstitutionChoiceComponent, canActivate: [AuthGuard] },
  { path: 'create-establishment', component: CreateEstablishmentComponent, canActivate: [AuthGuard] },
  { path: 'establishments', component: EstablishmentsComponent, canActivate: [AuthGuard] },
  { path: 'profile', component: ProfileComponent },
  { path: 'home', component: HomeComponent },
  { path: 'dashboard', component: DashboardComponent, canActivate: [AuthGuard] },
  { path: 'ai-prediction', component: AiPredictionComponent, canActivate: [AuthGuard] },
  { path: 'auto-learning', component: AutoLearningComponent, canActivate: [AuthGuard] },

  // Mobile workflow (ported from Flutter)
  { path: 'mobile', redirectTo: '/mobile/welcome', pathMatch: 'full' },
  { path: 'mobile/welcome', component: MobileWelcomeComponent },
  { path: 'mobile/auth', component: MobileAuthComponent },
  { path: 'mobile/choice', component: MobileInstitutionChoiceComponent, canActivate: [AuthGuard] },
  { path: 'mobile/map-selection', component: MobileMapSelectionComponent, canActivate: [AuthGuard] },
  { path: 'mobile/a1', component: MobileFormA1Component, canActivate: [AuthGuard] },
  { path: 'mobile/a2', component: MobileFormA2Component, canActivate: [AuthGuard] },
  { path: 'mobile/a3', component: MobileFormA3Component, canActivate: [AuthGuard] },
  { path: 'mobile/a4', component: MobileFormA4Component, canActivate: [AuthGuard] },
  { path: 'mobile/a5', component: MobileFormA5Component, canActivate: [AuthGuard] },
  { path: 'mobile/b1', component: MobileFormB1Component, canActivate: [AuthGuard] },
  { path: 'mobile/b2', component: MobileFormB2Component, canActivate: [AuthGuard] },
  { path: 'mobile/b3', component: MobileFormB3Component, canActivate: [AuthGuard] },
  { path: 'mobile/b4', component: MobileFormB4Component, canActivate: [AuthGuard] },
  { path: 'mobile/b5', component: MobileFormB5Component, canActivate: [AuthGuard] },
  { path: 'mobile/review', component: MobileReviewComponent, canActivate: [AuthGuard] },
  { path: 'mobile/result-choice', component: MobileResultChoiceComponent, canActivate: [AuthGuard] },
  { path: 'mobile/results/calculation', component: MobileCalculationResultsComponent, canActivate: [AuthGuard] },
  { path: 'mobile/results/comprehensive', component: MobileComprehensiveResultsComponent, canActivate: [AuthGuard] },
  
  // Web workflow NEW
  { path: 'web/b1', component: WebFormB1Component, canActivate: [AuthGuard] },
  { path: 'web/b2', component: WebFormB2Component, canActivate: [AuthGuard] },
  { path: 'web/b3', component: WebFormB3Component, canActivate: [AuthGuard] },
  { path: 'web/b4', component: WebFormB4Component, canActivate: [AuthGuard] },
  { path: 'web/b5', component: WebFormB5Component, canActivate: [AuthGuard] },
  
  { path: '**', redirectTo: '/home' }
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule {}


