import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { HttpClientModule } from '@angular/common/http';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { NgChartsModule } from 'ng2-charts';
import { CommonModule } from '@angular/common';
import { LeafletModule } from '@asymmetrik/ngx-leaflet';

import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { NavigationComponent } from './components/navigation/navigation.component';
import { DashboardComponent } from './pages/dashboard/dashboard.component';
import { AiPredictionComponent } from './pages/ai-prediction/ai-prediction.component';
import { AutoLearningComponent } from './pages/auto-learning/auto-learning.component';
import { HistoryComponent } from './pages/history/history.component';
import { LoginComponent } from './pages/login/login.component';
import { RegisterComponent } from './pages/register/register.component';
import { WelcomeComponent } from './pages/welcome/welcome.component';
import { CreateEstablishmentComponent } from './pages/create-establishment/create-establishment.component';
import { EstablishmentsComponent } from './pages/establishments/establishments.component';
import { MetricCardComponent } from './components/metric-card/metric-card.component';

@NgModule({
  declarations: [
    AppComponent,
    NavigationComponent,
    DashboardComponent,
    AiPredictionComponent,
    AutoLearningComponent,
    HistoryComponent,
    LoginComponent,
    RegisterComponent,
    WelcomeComponent,
    CreateEstablishmentComponent,
    EstablishmentsComponent,
    MetricCardComponent
  ],
  imports: [
    BrowserModule,
    BrowserAnimationsModule,
    CommonModule,
    AppRoutingModule,
    HttpClientModule,
    FormsModule,
    ReactiveFormsModule,
    NgChartsModule,
    LeafletModule
  ],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule { }
