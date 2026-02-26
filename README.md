# 自动记账 App - iOS 快捷指令方案

## 架构

```
┌─────────────────┐     URL Scheme      ┌─────────────────┐
│  iOS 快捷指令    │ ──────────────────→ │   记账 App      │
│  (读取通知)     │                     │  (Flutter)      │
└─────────────────┘                     └─────────────────┘
                                               │
                                               ▼
                                        ┌──────────────┐
                                        │  本地数据库   │
                                        │   (SQLite)   │
                                        └──────────────┘
```

## 数据流

1. 微信/支付宝支付 → 发送通知
2. 快捷指令读取通知内容
3. 解析金额、商家、时间
4. 通过 URL Scheme 打开记账 App 并传入数据
5. App 接收数据 → 存储 → 展示

## URL Scheme 格式

```
accounting://add?amount=123.50&merchant=星巴克&category=餐饮&time=2024-01-15T14:30:00
```

## 快捷指令配置步骤

1. 创建自动化 → 收到通知时（微信/支付宝）
2. 获取通知内容
3. 正则提取金额、商家
4. 打开 URL: `accounting://add?amount=...`

## 项目结构

```
lib/
├── main.dart              # 入口
├── app.dart               # App 配置
├── models/
│   └── transaction.dart   # 交易数据模型
├── screens/
│   ├── home_screen.dart   # 首页/列表
│   ├── add_screen.dart    # 手动记账
│   └── stats_screen.dart  # 统计图表
├── services/
│   ├── database_service.dart    # 数据库
│   └── url_handler_service.dart # URL Scheme 处理
└── widgets/
    └── transaction_card.dart    # 交易卡片
```
