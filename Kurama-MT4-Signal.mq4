//+------------------------------------------------------------------+
//|                       Kurama-MT4-Signal                          |
//|                 by Mohamed Hamed (github.com/Kurama-90)          |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_color1 Green
#property indicator_color2 Red
#property indicator_color3 Green
#property indicator_color4 Red

extern int ATRPeriod = 10;
extern double Multiplier = 3.0;

double UpTrendBuffer[];
double DownTrendBuffer[];
double BuySignalBuffer[];
double SellSignalBuffer[];

//+------------------------------------------------------------------+
int init() {
   SetIndexStyle(0, DRAW_LINE);
   SetIndexBuffer(0, UpTrendBuffer);
   SetIndexLabel(0, "Up Trend");

   SetIndexStyle(1, DRAW_LINE);
   SetIndexBuffer(1, DownTrendBuffer);
   SetIndexLabel(1, "Down Trend");

   SetIndexStyle(2, DRAW_ARROW);
   SetIndexArrow(2, 233); // Flèche vers le haut
   SetIndexBuffer(2, BuySignalBuffer);
   SetIndexLabel(2, "Buy Signal");

   SetIndexStyle(3, DRAW_ARROW);
   SetIndexArrow(3, 234); // Flèche vers le bas
   SetIndexBuffer(3, SellSignalBuffer);
   SetIndexLabel(3, "Sell Signal");

   ArraySetAsSeries(UpTrendBuffer, true);
   ArraySetAsSeries(DownTrendBuffer, true);
   ArraySetAsSeries(BuySignalBuffer, true);
   ArraySetAsSeries(SellSignalBuffer, true);

   return(0);
}

//+------------------------------------------------------------------+
int start() {
   int limit = Bars - ATRPeriod - 1;

   int trend = 1;
   double upPrev = 0.0;
   double dnPrev = 0.0;
   int trendPrev = trend;

   for (int i = limit; i >= 0; i--) {
      double currentATR = iATR(NULL, 0, ATRPeriod, i);
      double src = (High[i] + Low[i]) / 2.0;
      double up = src - Multiplier * currentATR;
      double dn = src + Multiplier * currentATR;

      // Trail stop logique
      up = Close[i+1] > upPrev ? MathMax(up, upPrev) : up;
      dn = Close[i+1] < dnPrev ? MathMin(dn, dnPrev) : dn;

      trendPrev = trend;

      if (trend == -1 && Close[i] > dnPrev)
         trend = 1;
      else if (trend == 1 && Close[i] < upPrev)
         trend = -1;

      if (trend == 1) {
         UpTrendBuffer[i] = up;
         DownTrendBuffer[i] = EMPTY_VALUE;
      } else {
         DownTrendBuffer[i] = dn;
         UpTrendBuffer[i] = EMPTY_VALUE;
      }

      // Signaux d'achat / vente
      BuySignalBuffer[i] = EMPTY_VALUE;
      SellSignalBuffer[i] = EMPTY_VALUE;

      if (trend == 1 && trend != trendPrev)
         BuySignalBuffer[i] = Low[i] - 10 * Point;

      if (trend == -1 && trend != trendPrev)
         SellSignalBuffer[i] = High[i] + 10 * Point;

      upPrev = up;
      dnPrev = dn;
   }
   
   // Ajout du tableau de tendances
   DrawTrendTable();
   
   return(0);
}

//+------------------------------------------------------------------+
//| Fonction pour dessiner le tableau de tendances                   |
//+------------------------------------------------------------------+
void DrawTrendTable()
{
   int x = 10; // Position X
   int y = 20; // Position Y
   int rowHeight = 20;
   int colWidth1 = 80; // Trend
   int colWidth2 = 70; // Analysis
   int colWidth3 = 70; // Strength
   int colWidth4 = 40; // TF

   // Créer le fond du tableau
   if(ObjectFind("TrendTable_BG") < 0)
   {
      ObjectCreate("TrendTable_BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSet("TrendTable_BG", OBJPROP_BGCOLOR, clrBlack);
      ObjectSet("TrendTable_BG", OBJPROP_BORDER_COLOR, clrGray);
   }
   ObjectSet("TrendTable_BG", OBJPROP_XDISTANCE, x);
   ObjectSet("TrendTable_BG", OBJPROP_YDISTANCE, y);
   ObjectSet("TrendTable_BG", OBJPROP_XSIZE, colWidth1+colWidth2+colWidth3+colWidth4);
   ObjectSet("TrendTable_BG", OBJPROP_YSIZE, rowHeight*8);

   // En-têtes de colonnes
   CreateLabel("H_Trend", x, y, "Trend", colWidth1, clrWhite, clrBlack);
   CreateLabel("H_Analysis", x+colWidth1, y, "Analysis", colWidth2, clrWhite, clrBlack);
   CreateLabel("H_Strength", x+colWidth1+colWidth2, y, "Strength", colWidth3, clrWhite, clrBlack);
   CreateLabel("H_TF", x+colWidth1+colWidth2+colWidth3, y, "TF", colWidth4, clrWhite, clrBlack);

   // Timeframes analysés
   int timeframes[6] = {PERIOD_H4, PERIOD_H1, PERIOD_M30, PERIOD_M15, PERIOD_M5, PERIOD_M1};
   string tfLabels[6] = {"H4", "H1", "M30", "M15", "M5", "M1"};

   // Remplir les données
   for(int i = 0; i < 6; i++)
   {
      int currentY = y + (i+1)*rowHeight;
      string trend = GetTrendDirection(timeframes[i]);
      string analysis = GetTrendAnalysis(timeframes[i]);
      string strength = GetTrendStrength(timeframes[i]);
      
      color trendClr = (trend == "BULLISH") ? clrGreen : clrRed;
      color strengthClr = (strength == "STRONG") ? clrGold : clrOrange;

      CreateLabel("R"+tfLabels[i]+"_Trend", x, currentY, trend, colWidth1, trendClr, clrBlack);
      CreateLabel("R"+tfLabels[i]+"_Analysis", x+colWidth1, currentY, analysis, colWidth2, clrWhite, clrBlack);
      CreateLabel("R"+tfLabels[i]+"_Strength", x+colWidth1+colWidth2, currentY, strength, colWidth3, strengthClr, clrBlack);
      CreateLabel("R"+tfLabels[i]+"_TF", x+colWidth1+colWidth2+colWidth3, currentY, tfLabels[i], colWidth4, clrWhite, clrBlack);
   }

   // Ligne de signal
   int signalY = y + 7*rowHeight;
   string signal = GetCurrentSignal();
   color signalClr = (signal == "BUY") ? clrGreen : clrRed;
   CreateLabel("Signal_Label", x, signalY, "-- Entry Signal --", colWidth1+colWidth2, clrWhite, clrBlack);
   CreateLabel("Signal_Value", x+colWidth1+colWidth2, signalY, signal, colWidth3+colWidth4, signalClr, clrBlack);
}

//+------------------------------------------------------------------+
//| Fonctions utilitaires pour le tableau                            |
//+------------------------------------------------------------------+
string GetTrendDirection(int tf)
{
   double current = iCustom(NULL, tf, "Supertrend", ATRPeriod, Multiplier, 0, 0);
   return (current == EMPTY_VALUE) ? "BULLISH" : "BEARISH";
}

string GetTrendAnalysis(int tf)
{
   double current = iCustom(NULL, tf, "Supertrend", ATRPeriod, Multiplier, 0, 0);
   return (current == EMPTY_VALUE) ? "UP" : "DOWN";
}

string GetTrendStrength(int tf)
{
   int count = 0;
   for(int i = 0; i < 10; i++)
   {
      if(iCustom(NULL, tf, "Supertrend", ATRPeriod, Multiplier, 0, i) == EMPTY_VALUE) count++;
   }
   return (count >= 7 || count <= 3) ? "STRONG" : "MODERATE";
}

string GetCurrentSignal()
{
   for(int i = 0; i < 10; i++)
   {
      if(BuySignalBuffer[i] != EMPTY_VALUE) return "BUY";
      if(SellSignalBuffer[i] != EMPTY_VALUE) return "SELL";
   }
   return "NONE";
}

void CreateLabel(string name, int x, int y, string text, int width, color textColor, color bgColor)
{
   if(ObjectFind(name) < 0) ObjectCreate(name, OBJ_LABEL, 0, 0, 0);
   ObjectSet(name, OBJPROP_XDISTANCE, x);
   ObjectSet(name, OBJPROP_YDISTANCE, y);
   ObjectSetText(name, text, 9, "Arial", textColor);
}
//+------------------------------------------------------------------+