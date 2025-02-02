+++
title = "TIL: mAP in information retrieval"
date = 2025-01-30
draft = false

[extra]
thumb = "img/map_moz_thumb.jpg"
math = true

[taxonomies]
categories = ["blog"]
tags = ["image_retrieval", "evaluation"]
+++

<img src="https://ggando.b-cdn.net/map.webp" alt="img0" width="500"/>

## Context
I've been working on an image search system based on image similarity for a client which returns N database images sorted by similarity score given a user's query image. I usually use top-k accuracy metrics where I check if any relevant image is included in the top-k samples or top-k unique categories in the returned result when evaluating image similarity systems.
However, we've reached a point where the model performed pretty well on the current datasets and the metrics became a bit too lenient, so we decided to include the mean average precision (mAP) in the model evaluation.

## mAP in IR
I knew that the mAP in object detection (OD) is the area under the precision-recall curve, but the definition of mAP seemed different in the information retrieval (IR) context at first. However, I realized that they're actually the same, and what made me confused are those `@K` metrics, defined differently from the original mAP. I'll explain this part later. I found [the Evidently AI's article](https://www.evidentlyai.com/ranking-metrics/mean-average-precision-map) explaining this mAP pretty comprehensive. It's already described well in the original post, but I'd like to add a few nuances that helped me understand this metric better.

### Situation
We have an IR or some kind of search system (items can be anything like documents or images) that returns K most similar items, given a query item from a user. We'd like to evaluate how good the returned result is for this particular query, and also want to know how well it performed for M queries on average. Each returned item can be "relevant" for user or "not relevant".

### P vs P@K vs AP vs AP@K
This was probably the most confusing part for me until I found this nice [TDS article](https://towardsdatascience.com/mean-average-precision-at-k-map-k-clearly-explained-538d8e032d2) clarifying this and I highly recommend going through it first.

First, we need to understand AP because mAP is just an averaged value of APs. To do s,o we start by understanding precision in IR.
Precision in IR is the same as OD and the denominator is the total number of retrieved (correct) items. Precision@K or P@K is just a precision with a fixed cutoff (K).
<div style="overflow-x: auto; white-space: nowrap;">
$$
\text{Precision} = \frac{\text{Number of relevant items retrieved}}{\text{Total number of retrieved items}}
$$
$$
\text{Precision@K} = \frac{\text{Number of relevant items in top } K}{K}
$$
</div>

Now, Average Precision (AP) vs AP@K:
<div style="overflow-x: auto; white-space: nowrap;">
$$
\text{AP} = \frac{1}{N} \sum_{i=1}^{N} \text{Precision@i} \times \text{Rel}(i)
$$
$$
\text{AP@K} = \frac{1}{R} \sum_{i=1}^{K} \text{Precision@i} \times \text{Rel}(i)
$$
</div>
Where $N$ is <u>the total number of relevant items in the dataset</u> and $R$ is <u>the total number of relevant items in the retrieved sequence</u>.
Unlike precision, the denominator is the actual total number of relevant items in the entire database, so if there are 10,000 relevant items in your DB you'd need to iterate over all of them to calculate this original AP. But practically we'd like to how precise the retrieval was, focusing on those retrieved items. This is where AP@K comes in—we only go through the relevant items within the retrieved sequence.

Both precision@K and AP@K measure how accurate the predictions are in identifying relevant items, but AP@K goes a step further by considering the order in which those relevant items appear. This focus on ranking is crucial in IR, where users expect the most relevant results to appear at the top of the list. While precision simply calculates the proportion of relevant items retrieved, it does not account for their positions in the ranking. As a result, precision cannot evaluate how well a system prioritizes relevant items in higher ranks, which is often key to a good user experience.

### mAP Formula in IR

The mean Average Precision (mAP) is simply the AP values averaged over multiple queries. If we have $M$ queries, each with its own AP, the formulae for mAP and mAP@K are:


<div style="overflow-x: auto; white-space: nowrap;">
$$
\text{mAP} = \frac{1}{M} \sum_{j=1}^{M} \text{AP}_j
$$

$$
\text{mAP@K} = \frac{1}{M} \sum_{j=1}^{M} \text{AP@K}_j
$$
</div>

Where:
- $M$ is the total number of queries,
- $\text{AP}_j$ is the Average Precision for the $j$-th query,
- $\text{AP@K}_j$ is the Average Precision at cutoff $K$ for the $j$-th query.

$M$ is just a user-specified parameter, so for example you can compute mAP for all the query items in your test set or per-category mAPs depending on your dataset.


### AP Example
To build some intuition I made a simple animated example here:
<!--<video controls>
  <source src="/vid/map0.mp4" type="video/mp4">
  Your browser does not support the video tag.
</video>-->
<img src="https://ggando.b-cdn.net/map0.gif" alt="img0" width="500"/>
<p class="break-words overflow-hidden">
This visualization was generated with a Python library `manim`. Source code: [Gist Link](https://gist.github.com/ggand0/9f5230ae384796244136ea089da8d5e4)
</p>

As you can see, we simply compute a precision at each relevant item and take the average of those:
```
precision = TP / (TP + FP)
precision@3 = 1 / (1 + 2) = 0.333
precision@5 = 2 / (2 + 3)  = 0.4
precision@8 = 3 / (3 + 5) = 0.375
```
In this particular example, the relevant items were scattered across ranks and two of the items were ranked at 5 and 8 even though they're relevant, resulting in a rather lower AP@10 of 0.369.

### My initial misunderstanding
As someone who's still a noob in IR, I wondered why we divide it by 3, not the actual number of relevant items in the above case at first, since most AP definitions online say the denominator of AP is "the total number of relevant items". It turns out that I was looking at the visualization of AP@K while refering to the definition of AP.  
Whether we're considering the entire database or just the retrieved sequence was the source of much of my confusion. Depending on your prompts, even GPT agents seem to mix these things up. So, I recommend reviewing the official definitions of these metrics in IR textbooks to confirm the standard explanations. For example, page 166 of the Manning's book "An Introduction to Information Retrieval" ([PDF link](https://nlp.stanford.edu/IR-book/pdf/irbookprint.pdf)) defines mAP without @K.

### Recall vs recall@K
These basically just regular recalls but recall@K has a cutoff point (K) for calculating the numerator term. Note that the denominator is both the total number of relevant items in the entire dataset for a particular query.

<div style="overflow-x: auto; white-space: nowrap;">
$$
\text{Recall} = \frac{\text{Number of relevant items retrieved}}{\text{Total number of relevant items in the dataset}}
$$
$$
\text{Recall@K} = \frac{\text{Number of relevant items in top } K}{\text{Total number of relevant items in the dataset}}
$$
</div>

## More intuitions
### Relation to precision-recall curve
As you may already know, just like in object detection, AP (not $AP@K$!) in IR is the area under the precision-recall (PR) curve. The PR curve is defined by (precision, recall) points at every relevant item in the dataset. You can think of AP as the AUC-PR because AP sums the precision at each relevant item. Summing precision at every relevant item is equivalent to adding a point at each recall level in the area calculation.


| Rank | Rel | Precision@K | Recall |
|---|---------|----------------|-----------|
| 1    | 0 | —              |  0/3 (0.00) |
| 2    | 0 | —              |  0/3 (0.00) |
| 3    | **1** | **1/3 = 0.33**  | **1/3 (0.333)** |
| 4    | 0 | —              |  1/3 (0.333) |
| 5    | **1** | **2/5 = 0.40**  | **2/3 (0.667)** |
| 6    | 0 | —              |  2/3 (0.667) |
| 7    | 0 | —              |  2/3 (0.667) |
| 8    | **1** | **3/8 = 0.375** | **3/3 (1.0)** |
| 9    | 0 | —              |  3/3 (1.0) |
| 10   | 0 | —              |  3/3 (1.0) |

NOTE: <u>This assumes an oversimplified situation where the total number of relevant items in DB is 3.</u>

<img src="/img/pr1_bad.png" alt="img0" width="500"/>

### Interpolated precision
This is also commonly known, but in IR evaluation, we often interpolate precision values to smooth out fluctuations (the sawtooth shape) in standard PR curves. This allows for a clearer comparison of PR curves across different systems. However, note that the area under the PR curve with interpolated precision does not equal AP. AP is equal to the AUC of original PR curve.
<img src="/img/pr2_bad.png" alt="img0" width="500"/>

### Sensitivity to early/late precisions
So far, I've used a simple example where the number of total relevant items is 3. Let’s scale things up with a case where the sequence length is 1,000 and the number of relevant items is 500. We assume that all 500 relevant items were retrieved within this sequence. 

To see how the distribution of relevant items affects the PR curve, we generate a set of sequences with varying early precisions. Specifically, we incrementally add more relevant items within the first 250 positions across different sequences. To ensure all the curves start from the same point, I fixed the first 10 retrieved items as all "relevant" in every sequence. Here’s the result:

<img src="https://ggando.b-cdn.net/pr4_early_fixed10.png" alt="img1" width="500"/>

We can observe that the PR curve is very sensitive to the precision of early retrieved items. The more relevant items you miss early on, the sharper the drop in the AP curve corresponding to them.

Here’s another example where we fix the first 50 items instead of 10. The part of the curve that drops to 0.6 remains the same, but it looks like you can still achieve a good AP if you start regaining high precision relatively early.

<img src="https://ggando.b-cdn.net/pr4_early_fixed50.png" alt="img1" width="500"/>

What if you retrieve more the relevant items towards the end? Here's another plot where we vary the number of relevant items retrieved from 0 to 250 in the last 250 items. The remaining relevant items are placed randomly in the rest of the sequence (0~750). In this case, the fewer relevant items you retrieve at the end, the higher the AUC, because that means more relevant items were retrieved earlier.

Relevant items retrieved later in the sequence still contribute to the AUC, but their impact is significantly less compared to relevant items retrieved in higher ranks.

<img src="https://ggando.b-cdn.net/pr4_late_notfixed.png" alt="img2" width="500"/>


### Historical context
I also did a bit of research on how this metric became popular among IR researchers, to learn more on why we use mAPs in the first place. I explored old IR books with GPT a little bit, and I think it comes down to these 3 reasons:
1. Comparing PR curves visually is difficult.
2. Single-value overall metric is easier to compare.
3. Standardization: AP became a standard metric for evaluating IR systems, especially in early benchmarks like the TREC competitions.

It seems that PR curves were already known and used in evaluation of IR systems in 60s-70s, before the introduction of mAP and other averaging metrics. They were pioneered by the works of researchers such as Gerard Salton and C. J. van Rijsbergen. 

Salton seems to already recognize issues of PR curve in his earlier works. For example, I found this paragraph in "Introduction to Modern Information Retrieval" third edition, which based on the original Salton's book, which seems to touch the point 1:
> Recall-precision graphs, such as that of Fig. 5-2b, have been criticized because a number of parameters are obscured. … Another problem arises when a number of curves such as the one of Fig. 5-2b, each valid for a single query, must be processed to obtain average performance characteristics for many user queries.

From here, evaluation metrics seemed to shift towards "averaging techniques" such as AP and "Precision at 11 Recall Levels" (another way to average precisions at fixed recall levels) in 70s-80s. However, it was the TREC (Text REtrieval Conference) in the 90s that particulary accelerated the adoption of this metric.

Before TREC, researchers used different datasets and metrics, making it hard to make fair comparision between IR systems. TREC introduced shared datasets and standard evaluation protocols, similar to what we see in many ML benchmarks today. I think that's why the TREC and metrics used in it became popular from that point on.

## Conclusion
AP@K in IR is just the sum of precisions caculated at each returned relevant item, allowing it to evaluate the performance by taking the ranking information into consideration. Now that I understand mAP@K, I feel this is a must-have metric for search systems evaluation. It provides a good single-value representation of retrieval quality, making it easier to compare different models. Hopefully this post gave you a bit more clarity on common IR metrics. Thanks for reading!