enum Province {
  //仅包含内地省份
  beijing(1, "北京市", "北京", "Beijing", "BJ"),
  tianjin(2, "天津市", "天津", "Tianjin", "TJ"),
  hebei(3, "河北省", "河北", "Hebei", "HE"),
  shanxi(4, "山西省", "山西", "Shanxi", "SX"),
  innerMongoria(5, "内蒙古自治区", "内蒙古", "Inner Mongoria", "NM"),
  liaoning(6, "辽宁省", "辽宁", "Liaoning", "LN"),
  jilin(7, "吉林省", "吉林", "Jilin", "JL"),
  heilongjiang(8, "黑龙江省", "黑龙江", "Heilongjiang", "HL"),
  shanghai(9, "上海市", "上海", "Shanghai", "SH"),
  jiangsu(10, "江苏省", "江苏", "Jiangsu", "JS"),
  zhejiang(11, "浙江省", "浙江", "Zhejiang", "ZJ"),
  anhui(12, "安徽省", "安徽", "Anhui", "AH"),
  fujian(13, "福建省", "福建", "Fujian", "FJ"),
  jiangxi(14, "江西省", "江西", "Jiangxi", "JX"),
  shandong(15, "山东省", "山东", "Shandong", "SD"),
  henan(16, "河南省", "河南", "Henan", "HA"),
  hubei(17, "湖北省", "湖北", "Hubei", "HB"),
  hunan(18, "湖南省", "湖南", "Hunan", "HN"),
  guangdong(19, "广东省", "广东", "Guangdong", "GD"),
  guangxi(20, "广西壮族自治区", "广西", "Guangxi", "GX"),
  hainan(21, "海南省", "海南", "Hainan", "HI"),
  chongqing(22, "重庆市", "重庆", "Chongqing", "CQ"),
  sichuan(23, "四川省", "四川", "Sichuan", "SC"),
  guizhou(24, "贵州省", "贵州", "Guizhou", "GZ"),
  yunnan(25, "云南省", "云南", "Yunnan", "YN"),
  tibet(26, "西藏自治区", "西藏", "Tibet", "XZ"),
  shaanxi(27, "陕西省", "陕西", "Shaanxi", "SN"),
  gansu(28, "甘肃省", "甘肃", "Gansu", "GS"),
  qinghai(29, "青海省", "青海", "Qinghai", "QH"),
  ningxia(30, "宁夏回族自治区", "宁夏", "Ningxia", "NX"),
  xinjiang(31, "新疆维吾尔自治区", "新疆", "Xinjiang", "XJ");

  final int id;
  final String name;
  final String shortName;
  final String enName;
  final String code;
  const Province(this.id, this.name, this.shortName, this.enName, this.code);

  static Province? fromId(int id) {
    try {
      return Province.values.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
