import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { HttpClientModule } from '@angular/common/http';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { NgChartsModule } from 'ng2-charts';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { LeafletModule } from '@asymmetrik/ngx-leaflet';

import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { NavigationComponent } from './components/navigation/navigation.component';
import { DashboardComponent } from './pages/dashboard/dashboard.component';
import { HomeComponent } from './pages/home/home.component';
import { AiPredictionComponent } from './pages/ai-prediction/ai-prediction.component';
import { AutoLearningComponent } from './pages/auto-learning/auto-learning.component';
import { LoginComponent } from './pages/login/login.component';
import { RegisterComponent } from './pages/register/register.component';
import { WelcomeComponent } from './pages/welcome/welcome.component';
import { InstitutionChoiceComponent } from './pages/institution-choice/institution-choice.component';
import { CreateEstablishmentComponent } from './pages/create-establishment/create-establishment.component';
import { EstablishmentsComponent } from './pages/establishments/establishments.component';
import { MetricCardComponent } from './components/metric-card/metric-card.component';
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
import { FormProgressComponent } from './mobile-workflow/widgets/form-progress/form-progress.component';
import { HierarchicalTypeSelectorComponent } from './mobile-workflow/widgets/hierarchical-type-selector/hierarchical-type-selector.component';

@NgModule({
  declarations: [
    AppComponent,
    DashboardComponent,
    HomeComponent,
    AiPredictionComponent,
    AutoLearningComponent,
    LoginComponent,
    RegisterComponent,
    WelcomeComponent,
    InstitutionChoiceComponent,
    EstablishmentsComponent,
    MetricCardComponent,
    MobileWelcomeComponent,
    MobileAuthComponent,
    MobileInstitutionChoiceComponent,
    MobileMapSelectionComponent,
    MobileFormA1Component,
    MobileFormA2Component,
    MobileFormA3Component,
    MobileFormA4Component,
    MobileFormA5Component,
    MobileFormB1Component,
    MobileFormB2Component,
    MobileFormB3Component,
    MobileFormB4Component,
    MobileFormB5Component,
    MobileReviewComponent,
    MobileResultChoiceComponent,
    MobileCalculationResultsComponent,
    FormProgressComponent
  ],
  imports: [
    BrowserModule,
    BrowserAnimationsModule,
    CommonModule,
    RouterModule,
    AppRoutingModule,
    HttpClientModule,
    FormsModule,
    ReactiveFormsModule,
    NgChartsModule,
    LeafletModule,
    NavigationComponent,
    HierarchicalTypeSelectorComponent
  ],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule { }
