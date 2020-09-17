// SAH Orders Model
// Separable Preference
// Technology shock, preference shock separately
// Complete Market, Perfect Risk Sharing Case
// 2020/09/16
// Baek, McCrory, Messer, Mui (2020)

//****************************************************************************
//Define variables
//****************************************************************************
var Ch           ${C}$ (long_name='Consumption in a home region')
    Cf           ${C^{*}}$ (long_name='Consumption in a foregin region')
    Nh           ${N}$ (long_name='Labor in a home region')
    Nf           ${N^{*}}$ (long_name='Labor in a foregin region')
    wh           ${w}$ (long_name='Real wage in a home region')
    wf           ${w^{*}}$ (long_name='Real wage in a foregin region')
    Yh           ${Y_{H}}$ (long_name='Output in a home region')
    Yf           ${Y_{F}}}$ (long_name='Output in a foregin region')
    pi            ${\pi}$ (long_name='CPI inflation in a home region')
    pis           ${\pi^{*}}$ (long_name='CPI inflation in a foreignlo region')
    mch           ${mc_{H}}$ (long_name='Real marginal cost in a home region')
    mcf           ${mc_{F}}$ (long_name='Real marginal cost in a foregin region')
    pih           ${\pi_{H}}$ (long_name='PPI inflation in a home region')
    pif           ${\pi_{F}}$ (long_name='PPI inflation in a foregin region')
    pish           ${\pi_{H}^{\#}}$ (long_name='Optimal PPI inflation in a home region')
    pisf           ${\pi_{F}^{\#}}$ (long_name='Optimal PPI inflation in a foregin region')
    vph           ${\Delta_{H}}$ (long_name='Price dispersion in a home region')
    vpf           ${\Delta^{*}}$ (long_name='Price dispersion in a foregin region')
    x1h           ${x_{H,1}}}$ (long_name='x1 in in a home region')
    x1f           ${x_{1}^{*}}$ (long_name='x1 in a foregin region')
    x2h           ${x_{H,2}}}$ (long_name='x2 in in a home region')
    x2f           ${x_{2}^{*}}$ (long_name='x2 in a foregin region')
    i             ${i}$ (long_name='interest rate')
    s             ${S}$ (long_name='Terms of Trade')
    gs            ${g(S)}$ (long_name='Function of Terms of Trade')
    gss           ${g^{*}(S)}$ (long_name='Function of Terms of Trade')
    N             ${N^{agg}}$ (long_name='Total Labor')
    C             ${C^{agg}}$ (long_name='Total Consumption')
    Y             ${Y^{agg}}$ (long_name='Total Output')
    Ah            ${A}$ (long_name='Technology in a home region')
    Af            ${A^{*}}$ (long_name='Technology in a foregin region')
    deltah        ${\delta}$ (long_name='Preference Shock in a home region')
    deltaf        ${\delta^{*}}$ (long_name='Preference Shock in a foregin region')
;

varexo epsi  ${\varepsilon_i}$ (long_name='monetary policy shock')
       epsh  ${\epsilon_{H}}$ (long_name='Technology shock in a home region')
       epsf  ${\epsilon_{F}}$ (long_name='Technology shock in a foregin region')
       epsd  ${\epsilon_{\delta}}$ (long_name='Preference shock in a home region')
       epsds ${\epsilon_{\delta *}}$ (long_name='Preference shock in a foregin region')
;

parameters 
    beta    ${\beta}$        (long_name='discount factor')
    psi     ${\psi}$         (long_name='labor disutility parameter')
    chi     ${\chi}$         (long_name='labor disutility parameter')
    sigma   ${\sigma}$       (long_name='elasticity of substitution')
    alpha   ${\alpha}$       (long_name='Returns to Scale Parameter')
    theta   ${\theta}$       (long_name='Calvo Parameter')
    eta     ${\eta}$         (long_name='Substitution across home and foreign')
    epsilon ${\epsilon}$     (long_name='Substitution across goods')
    phipi   ${\gamma}$       (long_name='MP on inflation')
    phiy    ${\epsilon}$     (long_name='MP on output')
    n       ${n}$            (long_name='Size of a home region')
    phiH    ${\phi_{H}}$     (long_name='phiH')
    phiF    ${\phi_{F}}$     (long_name='phiF')
    phiHs   ${\phi_{H}^{*}}$ (long_name='phiH star')
    phiFs   ${\phi_{F}^{*}}$ (long_name='phiF star')
    rhod    ${\rho_{\delta}}$ (long_name='Preference shock parameter home')
    rhods   ${\rho_{\delta^{*}}}$ (long_name='Preference shock parameter foreign')
    rhoA
    ;


//****************************************************************************
//Set parameter values
//****************************************************************************
sigma=1;
alpha= 2/3; % DRS parameter
beta=0.99;
psi = 1;
chi = 1;
theta = 0.75;
epsilon = 7;
eta = 2;
phipi = 1.5;
phiy = 0.5;
n = 0.1;
phiH = 0.69;
%phiH = n;
phiF = 1-phiH;
phiHs = (n/(1-n))*phiF; % We are interested in symmetric steady states
phiFs = 1-phiHs;
rhod = 0;
rhods = 0;
rhoA = 0;



//****************************************************************************
//Enter the model equations (model-block)
//***************************************************************************
model;
// Home Region
% (1)
[name='Euler equation in a home region per households']
(exp(deltah))*(exp(Ch))^(-sigma) = beta*((exp(deltah(+1)))*(exp(Ch(+1)))^(-sigma))*((1+i)/(1+pi(+1)));
% (2)
[name='Labor Supply in a home region per households']
exp(Nh) = ((exp(deltah))^(1/psi))*((1/chi)^(1/psi))*((exp(wh))^(1/psi))*((exp(gs))^(-1/psi))*(((exp(Ch)))^(-sigma/psi));
% (3)
[name='Labor Demand in a home region']
n*(exp(Nh)) = (((n*(exp(Yh)))/(exp(Ah)))^(1/alpha))*((exp(vph))^(1/alpha));
% (4)
[name='Aggregate real Marginal Cost in h']
(exp(mch))=((exp(wh))/alpha)*(((n*(exp(Yh)))^((1-alpha)/alpha))/((exp(Ah))^(1/alpha)));
% (5)
[name='Price Dispersion in a home region']
(exp(vph))=(1-theta)*((1+pish)^(-epsilon))*((1+pih)^(epsilon)) + ((1+pih)^(epsilon))*theta*(exp(vph(-1)));
% (6)
[name='Price Evolution in a home region']
((1+pih)^(1-epsilon))=(1-theta)*((1+pish)^(1-epsilon)) + theta;
% (7)
[name='Optimal Pricing Decision in a home region']
(1+pish)^((alpha + epsilon*(1-alpha))/alpha)=(epsilon/(epsilon-1))*((exp(x1h))/(exp(x2h)))*((1+pih)^((alpha+epsilon*(1-alpha))/alpha));
% (8)
[name='x1 in a home region']
(exp(x1h))=(exp(deltah))*((exp(Ch))^(-sigma))*((exp(mch)))*(n*(exp(Yh))) + theta*beta*((1+pih(+1))^(epsilon/alpha))*(exp(x1h(+1)));
% (9)
[name='x2 in a home region']
(exp(x2h))=(exp(deltah))*((exp(Ch))^(-sigma))*(n*(exp(Yh))) + theta*beta*((1+pih(+1))^(epsilon-1))*(exp(x2h(+1)));

// Foreign Region
% (10)
[name='Backus-Smith Condition']
(exp(deltah))*((exp(Ch))^(-sigma)) = (exp(deltaf))*((exp(Cf))^(-sigma))*((exp(gs))/(exp(gss)));
% (11)
[name='Labor Supply in a foreign region per households']
exp(Nf) = ((exp(deltaf))^(1/psi))*((1/chi)^(1/psi))*((exp(wf))^(1/psi))*(((exp(s))/(exp(gss)))^(1/psi))*(((exp(Cf)))^(-sigma/psi));
% (12)
[name='Labor Demand in a foreign region']
(1-n)*(exp(Nf)) = ((((1-n)*(exp(Yf)))/(exp(Af)))^(1/alpha))*((exp(vpf))^(1/alpha));
% (13)
[name='Real Marginal Cost in a foreign region']
(exp(mcf))=(exp(wf)/alpha)*((((1-n)*(exp(Yf)))^((1-alpha)/alpha))/((exp(Af))^(1/alpha)));
% (14)
[name='Price Dispersion in a foreign region']
(exp(vpf))=(1-theta)*((1+pisf)^(-epsilon))*((1+pif)^(epsilon)) + ((1+pif)^(epsilon))*theta*(exp(vpf(-1)));
% (15)
[name='Price Evolution in a foreign region']
((1+pif)^(1-epsilon))=(1-theta)*((1+pisf)^(1-epsilon)) + theta;
% (16)
[name='Optimal Pricing Decision in a foreign region']
(1+pisf)^((alpha+epsilon*(1-alpha))/alpha)=(epsilon/(epsilon-1))*((exp(x1f))/(exp(x2f)))*((1+pif)^((alpha+epsilon*(1-alpha))/alpha));
% (17)
[name='x1 in a foreign region']
(exp(x1f))=(exp(deltaf))*((exp(Cf))^(-sigma))*((exp(mcf)))*((1-n)*(exp(Yf))) + theta*beta*((1+pif(+1))^(epsilon/alpha))*(exp(x1f(+1)));
% (18)
[name='x2 in a foreign region']
(exp(x2f))=(exp(deltaf))*((exp(Cf))^(-sigma))*((1-n)*(exp(Yf))) + theta*beta*((1+pif(+1))^(epsilon-1))*(exp(x2f(+1)));

// Market Clearing, Internation Risk Sharing, Exogenous Processes, Some Definitions
% (19)
[name='Market Clearing Conditions of a home region']
n*(exp(Yh)) = phiH*((1/(exp(gs)))^(-eta))*(n*(exp(Ch))) + phiHs*((1/(exp(gss)))^(-eta))*((1-n)*(exp(Cf)));
% (20)
[name='Market Clearing Conditions of a foreign region']
(1-n)*(exp(Yf)) = phiF*(((exp(s))/(exp(gs)))^(-eta))*(n*(exp(Ch))) + phiFs*(((exp(s))/(exp(gss)))^(-eta))*((1-n)*(exp(Cf)));
%exp(Yf) + exp(Yh) = exp(Ch) + exp(Cf);
% (21)
[name='Definition of gs']
exp(gs) = (phiH + phiF*((exp(s))^(1-eta)))^(1/(1-eta));
% (22)
[name='Definition of g*(s)']
exp(gss) = (phiHs + phiFs*((exp(s))^(1-eta)))^(1/(1-eta));
% (23)
[name='Definition of ToT']
exp(s)/exp(s(-1)) = (1+pif)/(1+pih);
% (24)
[name='Relationship between CPI and PPI in a home region']
pi = phiH*pih + phiF*pif;
% (25)
[name='Relationship between CPI and PPI in a foreign region']
pis = phiHs*pih + phiFs*pif;
% (26)
[name='Monetary Policy']
i = (1/beta -1) + phipi*(n*pi + (1-n)*pis) + phiy*(n*(Yh-steady_state(Yh))+(1-n)*(Yf-steady_state(Yf)))  + epsi;
% (27)
[name='Total Labor']
exp(N) = n*exp(Nh) + (1-n)*exp(Nf);
% (28)
[name='Total Consumption']
exp(C) = n*exp(Ch) + (1-n)*exp(Cf);
% (29)
[name='Total Output']
exp(Y) = n*exp(Yh) + (1-n)*exp(Yf);
% (30)
[name='Technology in a Home Region']
Ah = rhoA*Ah(-1) + epsh ;
% (31)
[name='Technology in a Foreign Region']
Af = rhoA*Af(-1) + epsf;
% (32)
[name='Preference Shock in a Home Region']
deltah = rhod*deltah(-1) + epsd ;
%deltah = rhod*Ah + epsd ;
% (33)
[name='Preference shock in a Foreign Region']
deltaf = rhods*deltaf(-1) + epsds;
%deltaf = rhods*Af + epsds;
end;

initval;
i = 1/beta -1;
pih = 0;
pif = 0;
pi = 0;
pis = 0;
pish = 0;
pisf = 0;
s = 0;
gs = 0;
gss = 0;
vph = 0;
vpf = 0;
mch = log((epsilon-1)/epsilon);
mcf = log((epsilon-1)/epsilon);
Yh = (Ah + alpha*Nh - vph)-log(n);
Yf = (Af + alpha*Nf - vpf) - log(1-n);
x2h = -sigma*Ch + Yh - log(1-beta*theta);
x1h = -sigma*Ch + Yh + mch - log(1-beta*theta);
x2f = -sigma*Cf + Yf - log(1-beta*theta);
x1f = -sigma*Cf + Yf + mcf - log(1-beta*theta);
Ch = Cf;
Yh = Yf;
deltah = 0;
deltaf = 0;
end;

//****************************************************************************
//set shock variances
//****************************************************************************

shocks;
var epsi; stderr 0;
var epsh; stderr 0.007;
var epsf; stderr 0.007;
var epsd; stderr 0.01;
var epsds; stderr 0.01;
end;


//****************************************************************************
// compute steady state given the starting values
//****************************************************************************
steady;
check;

stoch_simul(order=1,noprint,nograph,irf=30);


//****************************************************************************
// Calculate IRFs (Home region only shock, Sticky Price)
//****************************************************************************
//initialize IRF generation
initial_condition_states = repmat(oo_.dr.ys,1,M_.maximum_lag);
// set technology shock
shock_matrix = zeros(options_.irf,M_.exo_nbr);
shock_matrix(1,strmatch('epsh',M_.exo_names,'exact')) = -1; 
// Calculate IRF
y_homeonly_sticky_tech = simult_(M_,options_,initial_condition_states,oo_.dr,shock_matrix,1);
irf_homeonly_sticky_tech = y_homeonly_sticky_tech(:,M_.maximum_lag+1:end)-repmat(oo_.dr.ys,1,options_.irf); %deviation from steady state
// set preference shock
shock_matrix = zeros(options_.irf,M_.exo_nbr);
shock_matrix(1,strmatch('epsd',M_.exo_names,'exact')) = -1; 
// Calculate IRF
y_homeonly_sticky_pref = simult_(M_,options_,initial_condition_states,oo_.dr,shock_matrix,1);
irf_homeonly_sticky_pref = y_homeonly_sticky_pref(:,M_.maximum_lag+1:end)-repmat(oo_.dr.ys,1,options_.irf); %deviation from steady state


//****************************************************************************
// Calculate IRFs (Home region only shock, Flexible Price)
//****************************************************************************
// Now Flexible Price Case
// set technology shock
shock_matrix = zeros(options_.irf,M_.exo_nbr);
shock_matrix(1,strmatch('epsh',M_.exo_names,'exact')) = -1; 
// Calculate IRF
set_param_value('theta', 0);
stoch_simul(order=1,noprint,nograph,irf=30);
y_homeonly_flex_tech = simult_(M_,options_,initial_condition_states,oo_.dr,shock_matrix,1);
irf_homeonly_flex_tech = y_homeonly_flex_tech(:,M_.maximum_lag+1:end)-repmat(oo_.dr.ys,1,options_.irf); %deviation from steady state
// set preference shock
shock_matrix = zeros(options_.irf,M_.exo_nbr);
shock_matrix(1,strmatch('epsd',M_.exo_names,'exact')) = -1; 
// Calculate IRF
y_homeonly_flex_pref = simult_(M_,options_,initial_condition_states,oo_.dr,shock_matrix,1);
irf_homeonly_flex_pref = y_homeonly_flex_pref(:,M_.maximum_lag+1:end)-repmat(oo_.dr.ys,1,options_.irf); %deviation from steady state



// Calculate IRF when persistence of preference shock = 0.9
set_param_value('theta', 0.75);
set_param_value('rhod', 0.9);
set_param_value('rhods', 0.9);
stoch_simul(order=1,noprint,nograph,irf=30);
// set preference shock
shock_matrix = zeros(options_.irf,M_.exo_nbr);
shock_matrix(1,strmatch('epsd',M_.exo_names,'exact')) = -1; 
// Calculate IRF
y_homeonly_sticky_pref9 = simult_(M_,options_,initial_condition_states,oo_.dr,shock_matrix,1);
irf_homeonly_sticky_pref9 = y_homeonly_sticky_pref9(:,M_.maximum_lag+1:end)-repmat(oo_.dr.ys,1,options_.irf); %deviation from steady state



//****************************************************************************
// Calculate Factors
//****************************************************************************

flex_tech_NX = n*(irf_homeonly_flex_tech(strmatch('Nh',M_.endo_names,'exact'),1)-irf_homeonly_flex_tech(strmatch('Nf',M_.endo_names,'exact'),1));
flex_tech_N = irf_homeonly_flex_tech(strmatch('N',M_.endo_names,'exact'),1);

flex_pref_NX = n*(irf_homeonly_flex_pref(strmatch('Nh',M_.endo_names,'exact'),1)-irf_homeonly_flex_pref(strmatch('Nf',M_.endo_names,'exact'),1));
flex_pref_N = irf_homeonly_flex_pref(strmatch('N',M_.endo_names,'exact'),1);

sticky_tech_NX = n*(irf_homeonly_sticky_tech(strmatch('Nh',M_.endo_names,'exact'),1)-irf_homeonly_sticky_tech(strmatch('Nf',M_.endo_names,'exact'),1));
sticky_tech_N = irf_homeonly_sticky_tech(strmatch('N',M_.endo_names,'exact'),1);

sticky_pref_NX = n*(irf_homeonly_sticky_pref(strmatch('Nh',M_.endo_names,'exact'),1)-irf_homeonly_sticky_pref(strmatch('Nf',M_.endo_names,'exact'),1));
sticky_pref_N = irf_homeonly_sticky_pref(strmatch('N',M_.endo_names,'exact'),1);

sticky_pref_NX9 = n*(irf_homeonly_sticky_pref9(strmatch('Nh',M_.endo_names,'exact'),1)-irf_homeonly_sticky_pref9(strmatch('Nf',M_.endo_names,'exact'),1));
sticky_pref_N9 = irf_homeonly_sticky_pref9(strmatch('N',M_.endo_names,'exact'),1);


flex_tech_Nh = irf_homeonly_flex_tech(strmatch('Nh',M_.endo_names,'exact'),1);
flex_tech_Nf = irf_homeonly_flex_tech(strmatch('Nf',M_.endo_names,'exact'),1);

flex_pref_Nh = irf_homeonly_flex_pref(strmatch('Nh',M_.endo_names,'exact'),1);
flex_pref_Nf = irf_homeonly_flex_pref(strmatch('Nf',M_.endo_names,'exact'),1);

sticky_tech_Nh = irf_homeonly_sticky_tech(strmatch('Nh',M_.endo_names,'exact'),1);
sticky_tech_Nf = irf_homeonly_sticky_tech(strmatch('Nf',M_.endo_names,'exact'),1);

sticky_pref_Nh = irf_homeonly_sticky_pref(strmatch('Nh',M_.endo_names,'exact'),1);
sticky_pref_Nf = irf_homeonly_sticky_pref(strmatch('Nf',M_.endo_names,'exact'),1);


% Table
% Flexible price, preference shock
disp('Flexible price, preference shock')
Total = flex_pref_N
Implied = flex_pref_NX
Factor = flex_pref_N/flex_pref_NX

% Sticky price, preference shock
disp('Sticky price, preference shock when persistence is zero')
Total = sticky_pref_N
Implied = sticky_pref_NX
Factor = sticky_pref_N/sticky_pref_NX

% Sticky price, preference shock
disp('Sticky price, preference shock when persistence is 0.9')
Total = sticky_pref_N9
Implied = sticky_pref_NX9
Factor = sticky_pref_N9/sticky_pref_NX9

% Flexible price, technology shock
disp('Flexible price, technology shock')
Total = flex_tech_N
Implied = flex_tech_NX
Factor = flex_tech_N/flex_tech_NX

% Sticky price, technology shock
disp('Sticky price, technology shock')
Total = sticky_tech_N
Implied = sticky_tech_NX
Factor = sticky_tech_N/sticky_tech_NX


figure,
scatter(1, flex_pref_Nh, 100, 'ko', 'filled'); hold on;  scatter(1, flex_pref_N, 100, 'ks'); hold on;  scatter(1, flex_pref_Nf, 100, 'kx', 'linewidth', 2); hold on;
scatter(2, flex_tech_Nh, 100, 'ko', 'filled'); hold on;  scatter(2, flex_tech_N, 100, 'ks'); hold on;  scatter(2, flex_tech_Nf, 100, 'kx', 'linewidth', 2); hold on;
scatter(3, sticky_pref_Nh, 100, 'ko', 'filled'); hold on;  scatter(3, sticky_pref_N, 100, 'ks'); hold on; scatter(3, sticky_pref_Nf, 100, 'kx', 'linewidth', 2); hold on;
scatter(4, sticky_tech_Nh, 100, 'ko', 'filled'); hold on;  scatter(4, sticky_tech_N, 100, 'ks'); hold on; scatter(4, sticky_tech_Nf, 100, 'kx', 'linewidth', 2); hold on;
plot([0:1:5], zeros(6,1), 'k:', 'linewidth', 1.5);
ax = gca(); 
ax.XTick = 1:4; 
row1 = {'Flexible', 'Flexible', 'Sticky' ,'Sticky'};
row2 = {'Preference', 'Technology' ,'Preference' ,'Technology'};
labelArray = [row1; row2]; 
tickLabels = strtrim(sprintf('%s\\newline%s\n', labelArray{:}));
ax.XTickLabel = tickLabels; 
%ax.TickLabelInterpreter = 'tex';
set(gca,'fontsize', 15);
[h, hobj] = legend('Home', 'Total', 'Foreign');
set(h, 'Location', 'Northwest');
M = findobj(hobj,'type','patch');
set(M,'MarkerSize', 15);
set(M,'linewidth', 3);
saveas(gcf, '../../output/plots/irf_onimpact.pdf');