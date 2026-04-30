





## YILDIZ TECHNICAL UNIVERSITY
## FACULTY OF CHEMICAL AND METALLURGY
## DEPARTMENT OF MATHEMATICAL ENGINEERING




## Multidisciplinary Design Project


Forecasting Earnings Surprises with Artificial
## Intelligence Techniques





Assoc. Prof. Gökhan GÖKSU

22058023, Kuzey SINAY






## Istanbul, 2025

ii











































© All rights to this thesis are reserved by the Department of Mathematical
## Engineering, Yıldız Technical University.

iii
## TABLE OF CONTENTS
SYMBOL	LIST	..............................................................................................................................................................	İV
ABBREVATION	LIST	...................................................................................................................................................	V
ABSTRACT	...................................................................................................................................................................	Vİ
- INTRODUCTION	..................................................................................................................................................	1
1.1.	BACKGROUND	AND	MOTİVATİON	...................................................................................................................................	1
1.2.	PROBLEM	DEFİNİTION,	AİM	AND	SCOPE	.......................................................................................................................	1
1.2.1.	Problem	Definition	.................................................................................................................................................	2
1.2.2.	Aim	of	the	Study	......................................................................................................................................................	2
1.2.3.	Scope	of	the	Study	...................................................................................................................................................	2
1.3.	REVİEW	OF	RELATED	WORKS	.........................................................................................................................................	2
1.3.1.	Foundational	Studies	on	Market	Efficiency	and	Anomalies	................................................................	2
1.3.2.	Econometric	and	Classical	Machine	Learning	Approaches	.................................................................	3
1.3.3.	State-of-the-Art:	Deep	Learning	and	Alternative	Data	..........................................................................	3
- PROPOSED	METHODOLOGY	...........................................................................................................................	4
2.1.	KEY	CONCEPTS	AND	THEORETİCAL	FRAMEWORK	..............................................................................................................	4
2.2.	TASK	FORMULATİON:	REGRESSİON	VS.	CLASSİFİCATİON	...................................................................................................	5
2.3.	A	MULTİMODAL	PREDİCTİVE	FRAMEWORK	.................................................................................................................	5
APPROACH	AND	ERA	.................................................................................................................................................	5
2.4.	DATA	MODALİTİES	AND	FEATURE	ENGİNEERİNG	...............................................................................................................	6
2.4.1.	Modality	1:	Structured	(Tabular)	Time-Series	Data	.........................................................................................	6
2.4.2.	Modality	2:	Unstructured	(Textual)	Data	..............................................................................................................	6
2.5.	PROPOSED	MODEL	ARCHİTECTURE	.......................................................................................................................................	7
- IMPLEMENTATION	AND	EXPERIMENTAL	SETUP	...................................................................................	8
3.1.	DEVELOPMENT	ENVİRONMENT	AND	TOOLS	.................................................................................................................	8
3.2.	DATA	PREPROCESSİNG	PİPELİNE	...........................................................................................................................................	8
3.2.1.	Processing	Modality	1:	Structured	Time-Series	..................................................................................................	8
3.2.2.	Processing	Modality	2:	Unstructured	Text	............................................................................................................	8
4.1.	THE	LSTM	ENCODER	(NUMERİC	STREAM)	.........................................................................................................................	9
4.2.	THE	FİNBERT	ENCODER	(TEXT	STREAM)	..........................................................................................................................	9
4.3.	MULTİMODAL	FUSİON	NETWORK	..........................................................................................................................................	9
- CURRENT	PROGRESS	AND	NEXT	STEPS	........................................................................................................	10
5.1.	ACHİEVEMENTS	.......................................................................................................................................................................	10
5.2.	FUTURE	WORK	........................................................................................................................................................................	10
REFERENCES	...............................................................................................................................................................	11
RESUME	........................................................................................................................................................................	15








iv







## SYMBOL LIST


## 푆푈퐸
## !

## Standardized Unanticipated Earnings
## 퐸푃푆
## !

Actual reported Earnings Per Share
## 퐸
Mean consensus analyst forecast
## 휎
## !

Standard deviation of analyst forecasts

















v





## ABBREVATION LIST

EPS Earnings Per Share
PEAD Post-Earnings Announcement Drift
EMH Efficient Market Hypothesis
AI Artificial Intelligence
ARIMA Autoregressive Integrated Moving Average
BERT Bidirectional Encoder Representations from Transformers
GRU Gated Recurrent Units
LSTM Long Short-Term Memory
MD&A Management Discussion & Analysis
ML Machine Learning
NLP Natural Language Processing
RF Random Forests
RNN Recurrent Neural Networks
SEC Securities and Exchange Commission
SUE Standardized Unanticipated Earnings
SVM Support Vector Machines






vi




## ABSTRACT
Corporate earnings announcements are critical events that often cause large stock price
movements.  This  project  focuses  on  the  Post-Earnings  Announcement  Drift  (PEAD)
anomaly, a well-documented market inefficiency where prices continue to drift long after a
surprise is announced. The central aim of this study is to develop a quantitative model using
Artificial Intelligence (AI) to effectively forecast these earnings surprises.

A key part of our methodology is framing the task as a regression problem: we will predict
the precise magnitude (size) of the surprise, not just its simple direction (a "Beat" or "Miss").
This approach is essential for identifying economically significant trading opportunities and
filtering out market noise.

The proposed technique is a multimodal deep learning framework. This model will imitate
human analysis by fusing two different types of data: (1) structured, time-series data (like
historical financial ratios) will be processed by an LSTM network to capture trends, and (2)
unstructured, textual data (from 10-Q reports, news articles, and social media) will be
processed by FinBERT to analyze sentiment and context.

These  two  streams  will  be  combined  to  predict  a  single,  robust  target  variable:  the
Standardized Unanticipated Earnings (SUE), which measures the surprise relative to analyst
uncertainty.



















vii




## 1
## 1. INTRODUCTION
This section provides a formal definition of the research topic, establishes its significance
within financial markets, defines the project's aim and scope, and reviews the academic
literature upon which this study is based. It also defines the core theoretical concepts that
serve as the foundation for the proposed methodology.
1.1. Background and Motivation
In financial markets, corporate earnings announcements are critical and information-rich
events.
## 1
The disclosure of a firm's quarterly Earnings Per Share (EPS) is a primary indicator
for the market to validate or recalibrate its valuation of the firm, frequently leading to
significant and immediate price adjustments.
The motivation for this project is to chase two distinct opportunities for generating market-
beating returns:
- Immediate And High-Volume Price Reaction: Occurs at the moment
the 'Earnings Surprise' (the deviation between actual EPS and consensus
analyst expectations) is publicly released.

- Post-Earnings Announcement Drift: The more profound opportunity is
an anomaly known as the "Post-Earnings Announcement Drift" (PEAD).
PEAD is the documented tendency for a stock's price to continue to 'drift'
in the direction of the surprise for weeks or even months following the
announcement.
## 2
This persistent drift represents a clear violation of the
semi-strong form of the Efficient Market Hypothesis (EMH), which posits
that  all  public  information  should  be  reflected  in  the  price  near-
instantaneously.
## 2

The fact that the PEAD anomaly continues to exist suggests the market is not perfectly
efficient, which creates a potential opportunity. The main goal of this project is therefore: to
build a strong quantitative tool that can separate "market noise"—which means random,
unimportant price changes—from the "real, tradable information" hidden in data before the
announcement.
## 4
## 1.2. Problem Definitıon, Aim And Scope
This section outlines the specific problem this project addresses, its formal objective, and its
operational boundaries.

## 2
## 1.2.1. Problem Definition
The central problem in this domain is the accurate forecasting of corporate earnings surprises.
Many existing models focus on simple directional classification ("Beat" or "Miss")
## 5
, an
approach that has been shown to be insufficient for developing viable, cost-aware trading
strategies.
## 7
1.2.2. Aim of the Study
The formal aim of this study is: To design, implement, and evaluate a quantitative model
utilizing  Artificial  Intelligence  (AI)  techniques  to  forecast  the  magnitude  of  'Earnings
Surprises' for equities in the US market.
## 7
1.2.3. Scope of the Study
The scope of this project is defined as follows:
● Market: The components of the S&P 500 index. This universe is selected due to its
high liquidity, market stability, and, most importantly, the extensive availability of high-
quality analyst consensus data (e.g., from I/B/E/S), which is essential for calculating the
target variable.
## 7


● Period: The study will utilize data from 2010 to 2025. This period is deliberately
chosen to train and test the model on modern market structures, which are dominated by
algorithmic and high-frequency trading. It consciously excludes the unique systemic
volatility of the 2008 financial crisis.
## 7


● Methodological Focus: As outlined in the aim, the project's focus is not merely on
classifying the direction of a surprise, but on forecasting its precise numerical magnitude
to identify economically significant events.
## 4

1.3. Review of Related Works
This section presents a review of the academic literature relevant to the project. The review
is structured chronologically to demonstrate the evolution of predictive methodologies, from
foundational theories to state-of-the-art techniques.
1.3.1. Foundational Studies on Market Efficiency and Anomalies
This research is based on the Efficient Market Hypothesis (EMH). EMH states that asset
prices include all information, making it impossible to get extra returns.
## 10
However, a lot of
research challenges this idea.
The most important study for this project is by Ball and Brown (1968).
## 13
This key paper was
the first to show two things: first, that accounting income numbers are useful to the market

## 3
## 18
; and second, that the market reacts to this information slowly. Ball and Brown saw a
continued price "drift" for firms with positive surprises and a negative drift for firms with
negative surprises.
## 19

This discovery of the PEAD anomaly
## 20
showed that market reactions are slow. This provides
the main academic reason for this project.
## 2
1.3.2. Econometric and Classical Machine Learning Approaches
Early models used methods like ARIMA (Autoregressive Integrated Moving Average) to
predict earnings.
## 21
The main problem was that these models assume financial data is simple
and linear, which it is not.
The first AI models in finance used classical machine learning (ML), like Support Vector
Machines (SVM) and Random Forests (RF), on structured  financial  data.
## 21
Their main
benefit was finding complex, non-linear patterns that simple regression models could not.
## 5

Studies showed these ML models were better than older models and sometimes even better
than human analysts.
## 5
1.3.3. State-of-the-Art: Deep Learning and Alternative Data
Current top methods involve two advances: using deep learning for time-series data and using
Natural Language Processing (NLP) for unstructured "alternative" data.
Deep learning models like Recurrent Neural Networks (RNNs), specifically LSTM and
GRU, were the next big step.
## 25
LSTMs are better than static models (like RF) because they
are built to find patterns in sequences of data. An LSTM can look at a sequence of financial
ratios over time, finding patterns like seasonality that static models miss.
## 28
Studies show
LSTMs are more accurate for EPS prediction than analysts and other models.
## 28

At the same time, a major change happened: models started analyzing text, not just numbers.
This means using NLP to find predictive signals in unstructured data like 1.0-K/1.0-Q
reports, news, and earnings call transcripts.
## 1
This text includes forward-looking information
that is not in the financial numbers.
This project will use a special NLP model for finance. General models (like BERT trained
on  Wikipedia)  do  not  work  well  because  financial  language  is  unique.
## 33
Models  like
FinBERT are pre-trained on many financial documents (like 1.0-Ks). They understand
financial  context  better  and  are  much  better  at  financial  sentiment  tasks  than  general
models.
## 34
While some studies in smaller markets (e.g., Poland) found simpler models were
just as good
## 38
, the proof for using models like FinBERT in the US market is strong.



## 4
## 2. PROPOSED METHODOLOGY
This section outlines the proposed technique for the design project. The methodology is a
direct synthesis of the findings from the literature review, designed to represent a state-of-
the-art approach to financial forecasting.
## 2.1. Key Concepts And Theoretical Framework
This section defines the core key concepts for the project, with a specific focus on the precise
definition of the target variable.
The project's success depends on a good definition of "Earnings Surprise." A simple "raw
surprise"  (e.g., 퐸푃푆
## "#$%&'
## −퐸푃푆
## ()*+,*+%+
)  is  uninformative,  as  a  $0.01$  surprise  is
meaningless  without  context.  A  "percentage  surprise"  (푆푢푟푝푟푖푠푒−퐸푃푆
## ()*+,*+%+
)  is
statistically problematic and highly unstable, as it is prone to extreme errors when the
denominator (consensus EPS) is near zero.
## 8
Therefore, this project will use a stronger, academically preferred metric: Standardized
Unanticipated Earnings (SUE). The concept was operationalized in foundational research
on the PEAD anomaly.
## 39

The SUE for a firm i is formally defined as:
## 푆푈퐸
## !
## =
## 퐸푃푆
## !
## −퐸
## 휎
## !

The components of this equation are:
## ● Numerator (퐸푃푆
## !
−퐸): The "raw surprise," calculated as the actual reported EPS
## 퐸푃푆
## !
minus the mean consensus analyst forecast (퐸).
## 40


## ● Denominator (휎
## !
): The standard deviation of all individual analyst forecasts for firm i
during the period.
## 40

The denominator, 휎
## !
, is the critical component. It is a measure of analyst uncertainty (how
much the analysts disagree).
## 8
The superiority of the SUE metric is best illustrated by two
examples:
- Case 1 (Low Uncertainty): Twenty analysts all forecast an EPS of $1.00$ (휎
## !
is near
zero). The firm reports $1.10$. The SUE value will be massive, as the firm delivered a
result that was far outside the confident consensus. This is a true, statistically
significant surprise.


## 5
- Case 2 (High Uncertainty): Ten analysts forecast $0.50$ and ten forecast $1.50$.
The mean consensus 퐸 is still $1.00$. The firm again reports $1.10$. In this case, the
denominator (휎
## !
) is huge. The resulting SUE value will be tiny. This is a false surprise;
it is just noise because the analysts were not sure.
By dividing the raw surprise by the level of analyst uncertainty, the SUE metric
automatically finds surprises that are statistically significant. It highlights events that beat a
strong agreement and ignores events that fall inside a wide, uncertain range. This makes
SUE the perfect target variable for a model that needs to find "tradable information".
## 4

## 2.2. Task Formulation: Regression Vs. Classification
We must make an important distinction about this predictive task. Many previous studies
tries to forecast direction of the surprise (e.g., a "Beat" or "Miss").
## 95
But only the direction is
not an enough forecast for a trustable trade strategy. A classification model treats a small,
unimportant surprise (e.g., actual EPS of $1.21$ vs. consensus of $1.20$) the same as a
massive, very significant surprise (e.g., actual EPS of $1.50$ vs. consensus of $1.20$). Both
are just called a "Beat".
## 7

Therefore, this project will frame the task as a regression problem: predicting the magnitude
of the surprise. This approach is essential for the project's goal. It allows the model to filter
out small-sized (and low-confidence) predictions that are likely to be "eaten" by transaction
costs and market noise.
## 4
A successful regression model allows a strategy to focus only on
large-sized, highly significant forecasts that have real economic potential.
## 48
## 2.3. A Multimodal Predictive Framework
Table 2.2 Evolution of earnings surprise prediction models
Approach and Era
## Data Type Example Key Limitation / Next Step
Foundational (1960s-1980s) Simple Time-Series Linear Regression
## 14
Too simple; misses complex patterns.
Econometric (1980s-2000s) Time-Series EPS ARIMA, GARCH
## 21
Still linear; ignores other firm data.
Classical ML (2015s-Present) Structured (Ratios) Random Forest, SVM
## 5
Good at non-linear patterns, but static;
misses time.
Deep Learning (Temporal)
(2015s-Present)
Structured (Time-Series) LSTM, GRU
## 28
Sees time, but blind to text/sentiment.
Deep Learning (Textual)
(2018s-Present)
Unstructured (Text) FinBERT
## 30
Sees text, but blind to time-series
numbers.
Proposed Multimodal Hybrid (Numbers + Text) Fused LSTM-FinBERT
## 45
Combines numbers and textual data

## 6

As shown in the literature review and Table 2.2, modern research has two main paths: (1)
using deep learning (like LSTMs) for structured number data, and (2) using NLP (like
FinBERT) for unstructured text data. A model that uses only one of these paths is missing a
lot of predictive information.
The proposed method is therefore a multimodal deep learning framework. This is a good
approach because the two data types (numbers and text) complete each other; they are not
repetitive. A human analyst reads both a balance sheet (numbers) and an earnings call (text)
to get the full story.
## 46
For instance, the number data (Modality 1) might show falling sales,
but the text data (Modality 2) might explain why, pointing to a new product that will reverse
this trend.
This combined approach (fusing numbers and text) is noted in recent academic papers as a
top method for financial forecasting.
## 45
## 2.4. Data Modalities And Feature Engineering
The model will be trained on two distinct data modalities, which will be engineered into
features for the neural network.
2.4.1. Modality 1: Structured (Tabular) Time-Series Data
This stream will consist of quantitative time-series data for each firm.
- Data Source: Publicly available financial datasets (e.g., Compustat, CRSP) or financial
data provider APIs.

- Features: A time-series vector will be constructed for each firm, incorporating data
from the preceding 8-16 quarters. This vector will include:

- Fundamental  Ratios: Key  financial  health  indicators  (e.g.,  Price-to-
Earnings, Return on Assets, Debt-to-Equity, gross/net profit margins).

- Market  Data: Historical  stock  volatility,  average  trading  volume,  and
momentum indicators.
- Consensus  Data: Analyst  consensus  forecast  (퐸),  standard  deviation  of
forecasts (휎
## !
), and historical SUE values (as an auto-regressive feature).
## 40


2.4.2. Modality 2: Unstructured (Textual) Data
This stream will consist of qualitative data extracted from a wide range of public sources.
- Data Source: This includes official documents like 10-K (annual) and 10-Q (quarterly)
reports filed with the SEC, and transcripts from quarterly earnings conference calls.
## 30

To broaden the analysis, this stream will also include alternative text sources such as

## 7
financial news articles, company press releases, and sentiment data from social media
posts.
## 20


- Feature Engineering (NLP): The text from the "Management Discussion & Analysis"
(MD&A) section of 10-Qs and the "Forward-Looking Statements" portion of earnings
calls will be processed using a pre-trained FinBERT model.
## 34


- Features: The FinBERT model will be used to generate two sets of features from the
text:
-   Sentiment Scores: A numerical value (positive, negative, neutral) representing
the tone of the text.
## 30

Semantic Embeddings: A high-dimensional vector (e.g., a [768x1] vector) that
represents the full semantic meaning and context of the management discussion.
This embedding is far more information-rich than a simple sentiment score.
## 34

## 2.5. Proposed Model Architecture
The proposed method is a multimodal neural network. It has two parallel 'streams' that
process data separately, an idea based on recent research.
## 45

- Stream 1 (For Numbers): An LSTM (or GRU) network will be used to
process the structured time-series data (Modality 1).
## 28
Because this is a 'recurrent'
network, it is designed to learn patterns over time, like trends and seasonality, from the
company's past financial numbers.

- Stream 2 (For Text): A pre-trained FinBERT model will be used to process
the unstructured text data (Modality 2).
## 34
This stream will read the text and output a
vector (embedding) that captures the text's meaning and the management's sentiment.

- Fusion Layer: The output vectors from Stream 1 (numbers) and Stream 2
(text) will be combined (or 'fused') into one single, wide vector.
## 45
This combined vector
represents the model's total understanding of both the firm's numbers and its text-based
context.
Output Layer (Regression): This final combined vector will be fed into a few standard
'Dense' layers. These layers will narrow down to a single output neuron. This final neuron
is trained (using Mean Squared Error) to predict one single number: the Standardized
Unanticipated Earnings (SUE).
## 40





## 8
## 3. IMPLEMENTATION AND EXPERIMENTAL SETUP
Following the theoretical framework established in the previous section, this chapter details
the practical implementation of the proposed multimodal architecture. The focus during this
phase has been on establishing the development environment, constructing the data
ingestion pipelines for both modalities, and implementing the core neural network modules.
3.1. Development Environment and Tools
The model is being developed using Python 3.10, leveraging the PyTorch framework for
deep learning tasks due to its dynamic computation graph and extensive support for NLP
transformers.
- Data Acquisition: yfinance library is utilized to fetch historical market data (Open,
High, Low, Close, Volume) and pandas for time-series manipulation. For textual
data, the SEC EDGAR database and publicly available financial corpus datasets are
accessed.
- NLP Backend: The transformers library by Hugging Face is used to implement the
pre-trained FinBERT model.
- Hardware: Preliminary training and testing are conducted on a cloud-based GPU
environment (T4/P100) to accelerate the fine-tuning process of the BERT layers.
## 3.2. Data Preprocessing Pipeline
A robust preprocessing pipeline is essential for multimodal learning. We have successfully
implemented two parallel processing streams:
3.2.1. Processing Modality 1: Structured Time-Series
Raw financial data often contains noise and missing values. The following steps have been
applied:
- Normalization: To ensure the LSTM converges efficiently, all financial ratios and
price data are normalized using MinMaxScaler to scale values between (0, 1).
- Sequence Generation: A sliding window approach has been coded to create input
sequences of length Τ=16 (representing 16 quarters of historical data) to predict
the earnings surprise of the (Τ+1)
## $-
quarter.
## 3.2.2. Processing Modality 2: Unstructured Text
For the textual stream, raw text from quarterly reports requires tokenization compatible
with FinBERT.
- Tokenization: We utilize the BertTokenizer pre-trained on the 'ProsusAI/finbert'
corpus.

## 9
- Truncation and Padding: Sequences are standardized to a maximum length of 512
tokens. Texts exceeding this limit are truncated to preserve the most critical sections
(typically the introduction and conclusion of MD&A sections), while shorter texts
are padded with [PAD] tokens.
## 4. PRELIMINARY ARCHITECTURE IMPLEMENTATION
In this phase, the theoretical model defined in Section 2.5 has been translated into
executable code. The architecture is modularized into three distinct Python classes.
4.1. The LSTM Encoder (Numeric Stream)
A custom TimeDistributed LSTM module has been implemented. This module takes the
tensor of shape (Batch_Size, Sequence_Length, Num_Features) and outputs a hidden state
vector representing the temporal financial context.
- Implementation Status: The LSTM class is fully defined with configurable hidden
dimensions and dropout layers to prevent overfitting.
4.2. The FinBERT Encoder (Text Stream)
We have integrated the BertModel from the transformers library. The weights are frozen
during the initial epochs to retain the financial linguistic knowledge learned during pre-
training, allowing only the top classification layers to update.
- Implementation Status: The text encoding pipeline successfully converts raw text
into 768-dimensional embeddings.
## 4.3. Multimodal Fusion Network
The core innovation of this project, the Fusion Layer, has been constructed. This layer
concatenates the output vector from the LSTM (Numeric) and the [CLS] token embedding
from FinBERT (Text).
## 푉
## !"#$%&
## =[	푉
## '()*
## ⊕푉
## +$&,-.)
## ]
This combined vector is then passed through a Fully Connected (Dense) network to regress
the final SUE value. Initial dry-run tests confirm that the data shapes align correctly across
both streams, allowing for end-to-end gradient flow.




## 10
## 5. CURRENT PROGRESS AND NEXT STEPS
## 5.1. Achievements
- Methodology Mastery: Successfully integrated NLP and Time-Series libraries
(PyTorch, Transformers).
- Data Pipeline: Automated fetching and cleaning of S&P 500 OHLCV data.
- Model Architecture: The complete MultimodalEarningsPredictor class is coded
and compiles without errors.
## 5.2. Future Work
The final phase will focus on the full-scale training of the model. This includes
hyperparameter tuning (learning rate, batch size) and comparative analysis against baseline
models (ARIMA and Random Forest). The final output will be the experimental results
demonstrating the Mean Squared Error (MSE) improvement over unimodal baselines.



















## 11
## REFERENCES
- Extracting the Structure of Press Releases for Predicting Earnings Announcement
Returns, erişim tarihi Kasım 8, 2025, https://arxiv.org/html/2509.24254v1
- (PDF) A review of the Post-Earnings-Announcement Drift, erişim tarihi Kasım 8,
2025, https://www.researchgate.net/publication/347976957_A_review_of_the_Post-
Earnings-Announcement_Drift
- A review of the Post-Earnings-Announcement Drift - IDEAS/RePEc, erişim tarihi
## Kasım 8, 2025,
https://ideas.repec.org/a/eee/beexfi/v29y2021ics2214635020303750.html
- Assessing the Effects of Earnings Surprise on ... - Duke Economics, erişim tarihi
Kasım 8, 2025, https://public.econ.duke.edu/~get/browse/courses/201/spr12/2010-
PRESENTATIONS/FullECON202-FINAL_PAPERS/2009-
December/Lim_Thesis.pdf
- Predicting Future Earnings Changes Using Machine ... - NYU Stern, erişim tarihi
## Kasım 8, 2025,
https://www.stern.nyu.edu/sites/default/files/assets/documents/SSRN-id3741015.pdf
- A Large Scale Multi-modal Benchmark for Earning Surprise Prediction - arXiv,
erişim tarihi Kasım 8, 2025, https://arxiv.org/html/2510.03965v1
- Streaks in Earnings Surprises and the Cross-Section of Stock Returns - Chapman
University Digital Commons, erişim tarihi Kasım 8, 2025,
https://digitalcommons.chapman.edu/cgi/viewcontent.cgi?article=1116&context=bus
iness_articles
- DD-050-Matematik Mühendisliği bitirme Çalışması ve Matematik Mühendisliğinde
## Tasarım Uygulaması Hazırlama Esasları.pdf
- How to measure earnings surprises: Based on revised market ... - NIH, erişim tarihi
Kasım 8, 2025, https://pmc.ncbi.nlm.nih.gov/articles/PMC10745228/
- THE EFFICIENT MARKET HYPOTHESIS ON TRIAL, erişim tarihi Kasım 8,
2025, https://www.westga.edu/~bquest/2002/market.htm
- The Efficient Market Hypothesis and Its Critics by Burton G. Malkiel, Princeton
University CEPS Working Paper No. 91, erişim tarihi Kasım 8, 2025,
https://www.princeton.edu/~ceps/workingpapers/91malkiel.pdf
- Redalyc.THE EFFICIENT MARKET HYPOTHESIS: A CRITICAL REVIEW OF
LITERATURE AND METHODOLOGY, erişim tarihi Kasım 8, 2025,
https://www.redalyc.org/pdf/6922/692273691006.pdf
- Ball & Brown (1968) | PDF | Cyberspace | Communication - Scribd, erişim tarihi
Kasım 8, 2025, https://www.scribd.com/document/644308442/Ball-Brown-1968
- Empirical Evaluation Of Accounting Income Numbers - IDEAS/RePEc, erişim tarihi
Kasım 8, 2025, https://ideas.repec.org/a/bla/joares/v6y1968i2p159-178.html
- Ball, R. and Brown, P. (1968) Empirical Evaluation of Accounting Income Numbers.
Journal of Accounting Research, 6, 159-178. - References - Scientific Research
Publishing, erişim tarihi Kasım 8, 2025,
https://www.scirp.org/reference/referencespapers?referenceid=2404068
- Why a 1968 Paper Still Influences Modern Asset Management - Knowledge at
Wharton, erişim tarihi Kasım 8, 2025,

## 12
https://knowledge.wharton.upenn.edu/podcast/knowledge-at-wharton-podcast/jacobs-
levy-award-2019/
- [PDF] An empirical evaluation of accounting income numbers - Semantic Scholar,
erişim tarihi Kasım 8, 2025, https://www.semanticscholar.org/paper/An-empirical-
evaluation-of-accounting-income-Ball-
## Brown/4d9595491bb8e21c527828e8483bc612bceaf773
- A REEXAMINATION OF BALL AND BROWN - Journal of Management and
Innovation, erişim tarihi Kasım 8, 2025,
https://jmi.mercy.edu/index.php/JMI/article/view/119/69
- The Strengths and Weaknesses of the 1968 'Ball and Brown' Study | UKEssays.com,
erişim tarihi Kasım 8, 2025, https://www.ukessays.com/essays/finance/review-of-the-
ball-and-brown-study-finance-essay.php
- Ball and Brown (1968) After Five Decades, erişim tarihi Kasım 8, 2025,
https://jacobslevycenter.wharton.upenn.edu/wp-content/uploads/2019/09/Ball-and-
Brown-Presentation.pdf
- A Review of ARIMA vs. Machine Learning Approaches for Time ..., erişim tarihi
Kasım 8, 2025, https://www.mdpi.com/1999-5903/15/8/255
- A bibliometric literature review of stock price forecasting: From statistical model to
deep learning approach - NIH, erişim tarihi Kasım 8, 2025,
https://pmc.ncbi.nlm.nih.gov/articles/PMC10943735/
- Comparison of SVM and ARIMA Model in Stock Market - Atlantis Press, erişim
tarihi Kasım 8, 2025, https://www.atlantis-press.com/article/125983649.pdf
- Man versus Machine Learning: The Term Structure of Earnings Expectations and
Conditional Biases | The Review of Financial Studies | Oxford Academic, erişim
tarihi Kasım 8, 2025, https://academic.oup.com/rfs/article/36/6/2361/6782974
- Forecasting S&P 500 Using LSTM Models - arXiv, erişim tarihi Kasım 8, 2025,
https://arxiv.org/html/2501.17366v1
- [2201.08218] Long Short-Term Memory Neural Network for Financial Time Series -
arXiv, erişim tarihi Kasım 8, 2025, https://arxiv.org/abs/2201.08218
- Advanced Stock Market Prediction Using Long Short-Term Memory Networks: A
Comprehensive Deep Learning Framework - arXiv, erişim tarihi Kasım 8, 2025,
https://arxiv.org/html/2505.05325v1
- Earnings Prediction with Deep Learning, erişim tarihi Kasım 8, 2025,
https://arxiv.org/abs/2006.03132
- Advanced Deep Learning Techniques for Analyzing Earnings Call Transcripts:
Methodologies and Applications - arXiv, erişim tarihi Kasım 8, 2025,
https://arxiv.org/html/2503.01886v1
## 30. LEVERAGING TEXT MINING TO EXTRACT INSIGHTS FROM EARNINGS
CALL TRANSCRIPTS - AllianceBernstein, erişim tarihi Kasım 8, 2025,
https://www.alliancebernstein.com/content/dam/global/insights/insights-
whitepapers/leveragingtextminingtoextractinsights-chinfan.pdf
- Using AI to unlock investment and risk management opportunities in earnings call
transcripts, erişim tarihi Kasım 8, 2025, https://www.lseg.com/en/insights/data-
analytics/ai-unlock-investment-risk-management-opportunities-earnings-call-
transcripts

## 13
- Assessing the Predictive Power of Earnings Call Transcripts on Next-Day Stock
Price Movement: A Semantic Analysis Using Large Language Models | UC Berkeley
School of Information, erişim tarihi Kasım 8, 2025,
https://www.ischool.berkeley.edu/projects/2024/assessing-predictive-power-
earnings-call-transcripts-next-day-stock-price-movement
- Financial Sentiment Analysis Using FinBERT with Application in Predicting Stock
Movement, erişim tarihi Kasım 8, 2025, https://arxiv.org/html/2306.02136v3
- (PDF) FinBERT: A Large Language Model for Extracting Information from
Financial Text†, erişim tarihi Kasım 8, 2025,
https://www.researchgate.net/publication/364070191_FinBERT_A_Large_Language
_Model_for_Extracting_Information_from_Financial_Text
- Fine-Tuned FinBERT Model with Sentiment Focus Method for Enhancing Sentiment
Analysis of FOMC Minutes - Alexandria (UniSG), erişim tarihi Kasım 8, 2025,
https://www.alexandria.unisg.ch/server/api/core/bitstreams/1d94cc0d-30b9-4d0d-
## 9131-8e8c20c46837/content
- FinBERT: A Pre-trained Financial Language Representation Model for Financial
Text Mining - IJCAI, erişim tarihi Kasım 8, 2025,
https://www.ijcai.org/proceedings/2020/0622.pdf
- Comparative Investigation of GPT and FinBERT's Sentiment Analysis Performance
in News Across Different Sectors - MDPI, erişim tarihi Kasım 8, 2025,
https://www.mdpi.com/2079-9292/14/6/1090
- Are Natural Language Processing methods applicable to EPS ..., erişim tarihi Kasım
## 8, 2025,
https://www.aimspress.com/article/doi/10.3934/DSFE.2025003?viewType=HTML
- Standardized Unexpected Earnings - QuantConnect.com, erişim tarihi Kasım 8,
2025, https://www.quantconnect.com/research/15369/standardized-unexpected-
earnings/
- The Impact of Individual and Collective Attribution on Earnings Calls ..., erişim
tarihi Kasım 8, 2025, https://repository.upenn.edu/bitstreams/2926ada1-fbba-4abc-
## 9f55-1ccc9a08ccc6/download
- (PDF) Borrower Distress and the Efficiency of Relationship Banking - ResearchGate,
erişim tarihi Kasım 8, 2025,
https://www.researchgate.net/publication/322345322_Borrower_Distress_and_the_E
fficiency_of_Relationship_Banking
- A New Measure of Earnings surprises and Post-Earnings-Announcement Drift -
Brandeis, erişim tarihi Kasım 8, 2025,
https://peeps.unet.brandeis.edu/~heidifox/ese.pdf
- Full article: Beyond the street EPS surprise – when 'other surprises' matter in
explaining earnings announcement returns, erişim tarihi Kasım 8, 2025,
https://www.tandfonline.com/doi/full/10.1080/00014788.2024.2400875
- Pre-Earnings Announcement Over-Extrapolation - Mendoza College of Business,
erişim tarihi Kasım 8, 2025, https://mendoza.nd.edu/wp-
content/uploads/2019/01/2016_spring_finance_seminar_series_peter_kelly_paper_up
dated_3_22_2016.pdf
- Financial Forecasting from Textual and Tabular Time Series - ACL ..., erişim tarihi

## 14
Kasım 8, 2025, https://aclanthology.org/2024.findings-emnlp.486/
- A Large Scale Multi-modal Benchmark for Earning Surprise ... - arXiv, erişim tarihi
Kasım 8, 2025, https://arxiv.org/pdf/2510.03965
- Financial Forecasting from Textual and Tabular Time Series - ACL Anthology,
erişim tarihi Kasım 8, 2025, https://aclanthology.org/2024.findings-emnlp.486.pdf
- Standardized Unexpected Earnings - University of West Georgia, erişim tarihi Kasım
8, 2025, https://www.westga.edu/~bquest/2002/unexpected.htm
- Dong Liang. Predicting Stock Price Changes with Earnings Call Transcripts. A
Master's - Carolina Digital Repository, erişim tarihi Kasım 8, 2025,
https://cdr.lib.unc.edu/downloads/j67317338
- Stock Price Prediction Using FinBERT-Enhanced Sentiment with SHAP
Explainability and Differential Privacy - MDPI, erişim tarihi Kasım 8, 2025,
https://www.mdpi.com/2227-7390/13/17/2747

































## 15
## Resume
Name Surname  Kuzey SINAY
Date of Birth               12.03.2004
Place of Birth  Manisa
## High School               2018 – 2022 Akhisar Fen Lisesi
## Internships  Turkcell Communication Services – (4 Weeks)
Borusan Otomotiv – (Current)


