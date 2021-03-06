## 流程
* 进入界面，选择球队，球员，球场，比赛时间
<!-- * 计算dominant color(grass field), 需要update -->
* 比赛开始，计时
* 一人记录一队
* 鼠标，键盘快捷键的点击来记录事件， 保存到数据库（各种事件需要根据规则确定），考虑如何记录人物和干了什么？？
* 每个事件可以截图保存（按照事件时间轴）
* 在long shot画面里面跟踪球和球员，当记录事件时，通过场地的监测计算出事件发生的位置，
* 每一条事件被打印在console里, console里有时间轴，可以在时间轴上回看事件

## 录入数据（目的）
* 所有门户网站的基本数据
* 事件时间，地点
* 防守，干扰，站位（optional）
* 过人
* 天气

## 事件
* 时间（自动）
* 地点（自动）
* 人物（手动）
* 怎么样（optional，一脚触角，内旋外旋。。。。。）
* 干了什么（射门，传球。。。。。）（手动）
* 暂停事件（任意球，犯规。。。。。更多数据）

## 如何记录人物和干了什么
* 按键鼠标如何操作
* 那些自动哪些手动
* 自动捕捉的数据的人工校对机制

## 算法结合
* tracking players
* tracking ball
* area classification
* partial ellipse detection
* goal mouth detection
* line detection
* shot type
* audio detection（关键词，哨声，评论员）
* team label, player label

## 主要算法：
  1. Dominant Color (paper1)
    * HSI 空间上计算直方图

  2. View Type/Shot Type (paper1)
    * 根据 Dominant Color/ Field Color 计算出每个镜头的场地面积百分比
    * 根据特定区域内的场地面积百分比区分long shot/middle shot/close up shot/non-field shot

  3. Field Position Classification (paper1)
    * Line
    * Particle ellipse
    * Goal mouth

  4. Team Labeling
    * Color

  5. Players Tracking

  6. Ball Tracking

  7. Ball Coordinator
    * ball tracking + field position classification

## 论文
1. automatic soccer video analysis and summarization
