import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { WelcomeComponent } from './pages/welcome/welcome.component';
import { LoginComponent } from './pages/login/login.component';
import { RegisterComponent } from './pages/register/register.component';
import { CreateEstablishmentComponent } from './pages/create-establishment/create-establishment.component';
import { EstablishmentsComponent } from './pages/establishments/establishments.component';
import { DashboardComponent } from './pages/dashboard/dashboard.component';
import { AiPredictionComponent } from './pages/ai-prediction/ai-prediction.component';
import { AutoLearningComponent } from './pages/auto-learning/auto-learning.component';
import { HistoryComponent } from './pages/history/history.component';
import { AuthGuard } from './guards/auth.guard';

const routes: Routes = [
  { path: '', redirectTo: '/welcome', pathMatch: 'full' },
  { path: 'welcome', component: WelcomeComponent },
  { path: 'login', component: LoginComponent },
  { path: 'register', component: RegisterComponent },
  { path: 'create-establishment', component: CreateEstablishmentComponent, canActivate: [AuthGuard] },
  { path: 'establishments', component: EstablishmentsComponent, canActivate: [AuthGuard] },
  { path: 'dashboard', component: DashboardComponent, canActivate: [AuthGuard] },
  { path: 'ai-prediction', component: AiPredictionComponent, canActivate: [AuthGuard] },
  { path: 'auto-learning', component: AutoLearningComponent, canActivate: [AuthGuard] },
  { path: 'history', component: HistoryComponent, canActivate: [AuthGuard] },
  { path: '**', redirectTo: '/dashboard' }
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }
