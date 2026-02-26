import 'package:flutter/material.dart';

// 标准账本分类体系（一级+二级）
// 参考：随手记、挖财、MoneyWiz、YNAB 等主流记账 App

class CategorySystem {
  // 一级分类
  static final Map<String, List<String>> categories = {
    // 1. 餐饮食品
    '餐饮食品': [
      '早餐',
      '午餐', 
      '晚餐',
      '零食饮料',
      '水果生鲜',
      '买菜做饭',
      '聚餐宴请',
      '外卖',
    ],
    
    // 2. 交通出行
    '交通出行': [
      '公交地铁',
      '打车网约车',
      '加油',
      '停车',
      '高速过路费',
      '保养维修',
      '车险',
      '火车高铁',
      '飞机',
    ],
    
    // 3. 购物消费
    '购物消费': [
      '衣服鞋帽',
      '化妆护肤',
      '电子数码',
      '日用百货',
      '母婴用品',
      '宠物用品',
      '图书文具',
      '运动户外',
    ],
    
    // 4. 居住物业
    '居住物业': [
      '房租',
      '房贷',
      '物业费',
      '水电煤',
      '宽带网络',
      '家具家电',
      '装修维护',
    ],
    
    // 5. 休闲娱乐
    '休闲娱乐': [
      '电影演出',
      '游戏充值',
      '视频会员',
      '音乐会员',
      '旅游度假',
      '运动健身',
      '兴趣爱好',
      '聚会社交',
    ],
    
    // 6. 医疗保健
    '医疗保健': [
      '挂号门诊',
      '药品',
      '体检',
      '医疗器械',
      '保健品',
      '牙科眼科',
      '心理咨询',
    ],
    
    // 7. 教育培训
    '教育培训': [
      '学费',
      '培训课程',
      '考试认证',
      '书籍资料',
      '在线教育',
      '留学出国',
    ],
    
    // 8. 人情往来
    '人情往来': [
      '送礼',
      '红包礼金',
      '请客吃饭',
      '孝敬长辈',
      '慈善捐赠',
    ],
    
    // 9. 金融保险
    '金融保险': [
      '保险',
      '投资理财',
      '贷款还款',
      '银行手续费',
      '税费',
    ],
    
    // 10. 通讯费用
    '通讯费用': [
      '手机话费',
      '短信费',
      '流量包',
      '视频通话',
    ],
    
    // 11. 其他支出
    '其他支出': [
      '丢失被盗',
      '罚款赔偿',
      '其他',
    ],
  };

  // 获取所有一级分类
  static List<String> get primaryCategories => categories.keys.toList();

  // 获取某个一级分类下的二级分类
  static List<String> getSubCategories(String primary) {
    return categories[primary] ?? ['其他'];
  }

  // 智能匹配（根据商家匹配到二级分类）
  static Map<String, String> smartMatch(String merchant) {
    final lower = merchant.toLowerCase();
    
    // 餐饮食品
    if (_containsAny(lower, ['麦当劳', '肯德基', '汉堡', '披萨', '早餐'])) {
      return {'一级': '餐饮食品', '二级': '早餐'};
    }
    if (_containsAny(lower, ['午餐', '快餐', '食堂', '便当'])) {
      return {'一级': '餐饮食品', '二级': '午餐'};
    }
    if (_containsAny(lower, ['晚餐', '饭店', '餐厅', '火锅', '烧烤', '日料', '韩餐'])) {
      return {'一级': '餐饮食品', '二级': '晚餐'};
    }
    if (_containsAny(lower, ['星巴克', '咖啡', '奶茶', '喜茶', '奈雪', '饮料', '零食'])) {
      return {'一级': '餐饮食品', '二级': '零食饮料'};
    }
    if (_containsAny(lower, ['盒马', '永辉', '超市', '买菜', '生鲜', '水果'])) {
      return {'一级': '餐饮食品', '二级': '买菜做饭'};
    }
    if (_containsAny(lower, ['聚餐', '宴请', '海底捞', '大排档'])) {
      return {'一级': '餐饮食品', '二级': '聚餐宴请'};
    }
    if (_containsAny(lower, ['美团', '饿了么', '外卖'])) {
      return {'一级': '餐饮食品', '二级': '外卖'};
    }
    
    // 交通出行
    if (_containsAny(lower, ['地铁', '公交', '一卡通'])) {
      return {'一级': '交通出行', '二级': '公交地铁'};
    }
    if (_containsAny(lower, ['滴滴', '高德', '打车', '网约车', '出租车', '曹操', '花小猪'])) {
      return {'一级': '交通出行', '二级': '打车网约车'};
    }
    if (_containsAny(lower, ['加油', '中石油', '中石化', '壳牌'])) {
      return {'一级': '交通出行', '二级': '加油'};
    }
    if (_containsAny(lower, ['停车', '停车费', '停车场'])) {
      return {'一级': '交通出行', '二级': '停车'};
    }
    if (_containsAny(lower, ['高速', '过路费', 'ETC'])) {
      return {'一级': '交通出行', '二级': '高速过路费'};
    }
    if (_containsAny(lower, ['保养', '维修', '4S店', '洗车'])) {
      return {'一级': '交通出行', '二级': '保养维修'};
    }
    if (_containsAny(lower, ['车险', '保险'])) {
      return {'一级': '交通出行', '二级': '车险'};
    }
    if (_containsAny(lower, ['火车', '高铁', '动车', '12306'])) {
      return {'一级': '交通出行', '二级': '火车高铁'};
    }
    if (_containsAny(lower, ['机票', '航空', '携程', '飞猪', '去哪儿'])) {
      return {'一级': '交通出行', '二级': '飞机'};
    }
    
    // 购物消费
    if (_containsAny(lower, ['淘宝', '天猫', '京东', '拼多多', '苏宁', '唯品会'])) {
      return {'一级': '购物消费', '二级': '日用百货'};
    }
    if (_containsAny(lower, ['优衣库', 'ZARA', 'H&M', '衣服', '鞋子', '包包'])) {
      return {'一级': '购物消费', '二级': '衣服鞋帽'};
    }
    if (_containsAny(lower, ['化妆品', '护肤', '丝芙兰', '屈臣氏', '美妆'])) {
      return {'一级': '购物消费', '二级': '化妆护肤'};
    }
    if (_containsAny(lower, ['苹果', '华为', '小米', '手机', '电脑', '数码'])) {
      return {'一级': '购物消费', '二级': '电子数码'};
    }
    if (_containsAny(lower, ['母婴', '奶粉', '尿布', '婴儿'])) {
      return {'一级': '购物消费', '二级': '母婴用品'};
    }
    if (_containsAny(lower, ['宠物', '猫粮', '狗粮', '宠物医院'])) {
      return {'一级': '购物消费', '二级': '宠物用品'};
    }
    if (_containsAny(lower, ['书店', '图书', '文具', '办公用品'])) {
      return {'一级': '购物消费', '二级': '图书文具'};
    }
    
    // 居住物业
    if (_containsAny(lower, ['房租', '租房'])) {
      return {'一级': '居住物业', '二级': '房租'};
    }
    if (_containsAny(lower, ['房贷', '月供'])) {
      return {'一级': '居住物业', '二级': '房贷'};
    }
    if (_containsAny(lower, ['物业', '物业费'])) {
      return {'一级': '居住物业', '二级': '物业费'};
    }
    if (_containsAny(lower, ['电费', '水费', '燃气', '水电'])) {
      return {'一级': '居住物业', '二级': '水电煤'};
    }
    if (_containsAny(lower, ['宽带', '网络', '电信', '移动', '联通', 'WiFi'])) {
      return {'一级': '居住物业', '二级': '宽带网络'};
    }
    if (_containsAny(lower, ['家具', '家电', '宜家', '装修'])) {
      return {'一级': '居住物业', '二级': '家具家电'};
    }
    
    // 休闲娱乐
    if (_containsAny(lower, ['电影', '影院', '淘票票', '猫眼'])) {
      return {'一级': '休闲娱乐', '二级': '电影演出'};
    }
    if (_containsAny(lower, ['游戏', 'Steam', '充值', '腾讯游戏', '网易游戏'])) {
      return {'一级': '休闲娱乐', '二级': '游戏充值'};
    }
    if (_containsAny(lower, ['爱奇艺', '腾讯', '优酷', 'B站', '会员', 'Netflix'])) {
      return {'一级': '休闲娱乐', '二级': '视频会员'};
    }
    if (_containsAny(lower, ['QQ音乐', '网易云', 'Spotify', '音乐'])) {
      return {'一级': '休闲娱乐', '二级': '音乐会员'};
    }
    if (_containsAny(lower, ['旅游', '酒店', '民宿', '机票', '景点'])) {
      return {'一级': '休闲娱乐', '二级': '旅游度假'};
    }
    if (_containsAny(lower, ['健身', '瑜伽', '游泳', '健身房', 'Keep'])) {
      return {'一级': '休闲娱乐', '二级': '运动健身'};
    }
    if (_containsAny(lower, ['KTV', '酒吧', '密室', '剧本杀'])) {
      return {'一级': '休闲娱乐', '二级': '聚会社交'};
    }
    
    // 医疗保健
    if (_containsAny(lower, ['医院', '挂号', '门诊', '急诊'])) {
      return {'一级': '医疗保健', '二级': '挂号门诊'};
    }
    if (_containsAny(lower, ['药店', '药房', '买药'])) {
      return {'一级': '医疗保健', '二级': '药品'};
    }
    if (_containsAny(lower, ['体检', '美年', '爱康'])) {
      return {'一级': '医疗保健', '二级': '体检'};
    }
    if (_containsAny(lower, ['牙科', '口腔', '眼科'])) {
      return {'一级': '医疗保健', '二级': '牙科眼科'};
    }
    
    // 教育培训
    if (_containsAny(lower, ['学费', '学校', '大学'])) {
      return {'一级': '教育培训', '二级': '学费'};
    }
    if (_containsAny(lower, ['培训', '课程', '新东方', '学而思', '网课'])) {
      return {'一级': '教育培训', '二级': '培训课程'};
    }
    if (_containsAny(lower, ['考试', '雅思', '托福', 'GRE', '考证'])) {
      return {'一级': '教育培训', '二级': '考试认证'};
    }
    if (_containsAny(lower, ['书', '教材', '资料'])) {
      return {'一级': '教育培训', '二级': '书籍资料'};
    }
    
    // 人情往来
    if (_containsAny(lower, ['礼物', '送礼', '鲜花'])) {
      return {'一级': '人情往来', '二级': '送礼'};
    }
    if (_containsAny(lower, ['红包', '礼金', '份子钱', '结婚', '生日'])) {
      return {'一级': '人情往来', '二级': '红包礼金'};
    }
    if (_containsAny(lower, ['请客', '招待'])) {
      return {'一级': '人情往来', '二级': '请客吃饭'};
    }
    
    // 金融保险
    if (_containsAny(lower, ['保险', '平安', '人寿', '健康险'])) {
      return {'一级': '金融保险', '二级': '保险'};
    }
    if (_containsAny(lower, ['理财', '基金', '股票', '投资'])) {
      return {'一级': '金融保险', '二级': '投资理财'};
    }
    if (_containsAny(lower, ['还款', '贷款', '信用卡'])) {
      return {'一级': '金融保险', '二级': '贷款还款'};
    }
    
    // 通讯费用
    if (_containsAny(lower, ['话费', '手机', '充值', '移动', '联通', '电信'])) {
      return {'一级': '通讯费用', '二级': '手机话费'};
    }
    
    // 默认
    return {'一级': '其他支出', '二级': '其他'};
  }

  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k.toLowerCase()));
  }

  // 获取分类图标
  static IconData getIcon(String primary) {
    final icons = {
      '餐饮食品': Icons.restaurant,
      '交通出行': Icons.directions_car,
      '购物消费': Icons.shopping_bag,
      '居住物业': Icons.home,
      '休闲娱乐': Icons.sports_esports,
      '医疗保健': Icons.local_hospital,
      '教育培训': Icons.school,
      '人情往来': Icons.card_giftcard,
      '金融保险': Icons.account_balance,
      '通讯费用': Icons.phone_android,
      '其他支出': Icons.more_horiz,
    };
    return icons[primary] ?? Icons.help_outline;
  }

  // 获取分类颜色
  static Color getColor(String primary) {
    final colors = {
      '餐饮食品': Colors.orange,
      '交通出行': Colors.blue,
      '购物消费': Colors.pink,
      '居住物业': Colors.brown,
      '休闲娱乐': Colors.purple,
      '医疗保健': Colors.red,
      '教育培训': Colors.green,
      '人情往来': Colors.teal,
      '金融保险': Colors.indigo,
      '通讯费用': Colors.cyan,
      '其他支出': Colors.grey,
    };
    return colors[primary] ?? Colors.grey;
  }
}
