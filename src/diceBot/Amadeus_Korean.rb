# -*- coding: utf-8 -*-

class Amadeus_Korean < DiceBot
  def initialize
    super
    @sendMode = 2
    @sortType = 1
    @d66Type = 2
  end

  def gameName
    '아마데우스'
  end

  def gameType
    "Amadeus:Korean"
  end

  def getHelpMessage
    return <<INFO_MESSAGE_TEXT
・판정(Rx±y@z>=t)
　다이스별로 성공, 실패의 판정을 합니다.
　x：x에 랭크(S,A～D)를 입력.
　y：y에 수정치를 입력. ±의 계산에 대응. 생략가능.
　z：z에 스페셜이 되는 주사위 눈의 최저치를 입력.
　생략한 경우, 6의 값만 스페셜이 됩니다.
　t：t에 목표치를 입력. ±의 계산에 대응. 생략가능.
　목표치를 생략한 경우, 목표치는 4로 계산됩니다.
　예） RA　RB-1　RC>=5　RD+2　RS-1@5>=6
　※ RB++ 나 RA- 같은, 플러스 마이너스만의 표기로는 계산되지 않습니다.
　"달성치"_"판정결과"["주사위 눈""대응하는 인과"]와 같이 출력됩니다.
　단, C.D랭크에서는 대응하는 인과가 출력되지 않습니다.
　출력예)　1_펌블！[1흑] / 3_실패[3청]
・각종표
　・조우표　ECT／관계표　RT／부모마음표　PRT／전장표　BST／휴식표　BT／
　　펌블표　FT／치명상표　FWT／전과표 BRT／랜덤아이템표　RIT／
　　손상표　WT／악몽표　NMT／목표표　TGT／制約表 CST
・試練表（～VT）
　ギリシャ神群 GCVT／ヤマト神群 YCVT／エジプト神群 ECVT／
　クトゥルフ神群 CCVT／北欧神群 NCVT／ダンジョン DGVT／日常 DAVT
・挑戦テーマ表（～CT）
　武勇 PRCT／技術 TCCT／頭脳 INCT／霊力 PSCT／愛 LVCT／日常 DACT
INFO_MESSAGE_TEXT
  end

  def rollDiceCommand(command)
    text = amadeusDice(command)
    return text unless( text.nil? )

    info = @@tables[command.upcase]
    return nil if info.nil?

    name = info[:name]
    type = info[:type]
    table = info[:table]

    text, number =
      case type
      when '1D6'
        get_table_by_1d6(table)
      when '2D6'
        get_table_by_2d6(table)
      when 'D66'
        get_table_by_d66_swap(table)
      else
        nil
      end

    return nil if( text.nil? )

    return "#{name}(#{number}) ＞ #{text}"
  end

  def amadeusDice(command)
    return nil unless( /^(R([A-DS])([\+\-\d]*))(@(\d))?((>(=)?)([\+\-\d]*))?(@(\d))?$/i =~ command )

    commandText = $1
    skillRank = $2
    modifyText = $3
    signOfInequality = ( $7.nil? ? ">=" : $7 )
    targetText = ( $9.nil? ? "4" : $9 )
    if( nil | $5 )
      specialNum = $5.to_i
    elsif( nil | $11 )
      specialNum = $11.to_i
    else
      specialNum = 6
    end

    diceCount = @@checkDiceCount[skillRank]
    modify = parren_killer("(" + modifyText + ")").to_i
    target = parren_killer("(" + targetText + ")").to_i

    _, diceText, = roll(diceCount, 6)
    diceList = diceText.split(/,/).collect{|i| i.to_i}
    specialText = ( specialNum == 6 ? "" : "@#{specialNum}" )

    message = "(#{commandText}#{specialText}#{signOfInequality}#{targetText}) ＞ [#{diceText}]#{modifyText} ＞ "
    diceList = [diceList.min] if( skillRank == "D" )
    is_loop = false
    for dice in diceList do
      if( is_loop )
        message += " / "
      elsif( diceList.length > 1)
        is_loop = true
      end
      achieve = dice + modify
      result = check_success(achieve, dice, signOfInequality, target, specialNum)
      if( is_loop )
        message += "#{achieve}_#{result}[#{dice}#{@@checkInga[dice]}]"
      else
        message += "#{achieve}_#{result}[#{dice}]"
      end
    end

    return message
  end

  def check_success(total_n, dice_n, signOfInequality, diff, special_n)
    return "펌블！" if( dice_n == 1 )
    return "스페셜！" if( dice_n >= special_n )

    success = bcdice.check_hit(total_n, signOfInequality, diff)
    return "성공" if(success >= 1)
    return "실패"
  end

  @@checkDiceCount = { "S" => 4, "A" => 3, "B" => 2, "C" => 1, "D" => 2 }
  @@checkInga = [ nil, "흑", "적", "청", "녹", "백", "임의" ]

  @@tables =
    {
    "ECT" => {
      :name => "조우표",
      :type => '1D6',
      :table => [
"고백. 당신은 신과 인간(짐승의 아이의 경우는 무언가의 동물)이 서로 사랑해 태어난 신의 아이입니다. 최근이 되어 그 사실과 예언에 관해 자신의 부모로부터 전해듣게 되었습니다. 당신은 양친이 있는 경우 어느 한쪽은 의붓부모가 됩니다.",
"고아. 당신은 부모에 대해 아무것도 몰랐습니다. 가혹한 환경에서 사는 동안, 당신의 형제자매가 당신을 맞이하러 왔습니다. 그리고 당신은 신의 아이이자, 예언의 당사자라는 것을 전해듣습니다.",
"가족. 당신은 신의 아이로서 어린 시절부터 생활해왔습니다. 현실과 <성지>를 왔다갔다하며 여러가지 것들을 신인 부모에게서 가르침 받았습니다. 그리고, 언젠가 모험에 나서, 영웅이 될 날을 즐겁게 기다리고 있었습니다.",
"혈맥. 당신의 일족에게는 '거대한 운명의 소유자가 태어난다'라고 하는 예언이 전해져 왔습니다. 그 예언의 아이가 당신입니다. 아마도, 당신의 먼 선조는 신이었을 것입니다. 일족은 당신에게 큰 기대와 두려움을 가지고 있습니다.",
"총애. 당신의 자질과 재능은 신에게 인정받았습니다. 그리고, 꿈 속에서 부모신과 만나, <신의 피>를 직접 하사받았습니다. 그 이후로, 당신은 불가사의한 것들이 보이거나 들리거나 하게 되었습니다.",
"귀의. 당신은 괴물에 의해 생명의 위협을 받았습니다. 하지만, 신의 피를 받은 것으로 죽음의 문턱에서 되돌아 왔습니다. 그 이후로, 당신은 당신을 구해준 신에게 귀의하여 인생을 바치기로 했습니다.",
],},

    "BST" => {
      :name => "전장표",
      :type => '1D6',
      :table => [
"묘지. 라운드 종료 시 PC와 괴물의 본체는 【생명력】이 1D6점 감소한다. PC가 기프트를 사용할 때 흑의 영역의 인과가 추가로 2개 있는것으로 취급한다.",
"시가지. 모든 PC와 괴물은 입히는 데미지가 1D6점 상승한다. PC가 기프트를 사용할 때 적의 영역의 인과가 추가로 2개 있는것으로 취급한다.",
"수중. 잠수상태가 아닌 PC는 모든 판정에 -1의 수정치가 붙는다. 라운드 종료 시, 잠수상태가 아닌 PC와 괴물의 본체는 【생명력】이 1D6점 감소한다. PC가 기프트를 사용할 때 청의 영역의 인과가 추가로 2개 있는것으로 취급한다.",
"삼림. 모든 PC와 괴물은 받는 데미지가 1D6점 감소한다. PC가 기프트를 사용할 때 녹의 영역의 인과가 추가로 2개 있는것으로 취급한다.",
"공중. 비행상태가 아닌 PC는 모든 판정에 -1의 수정치가 붙는다. 전투종료 시 괴물의 【생명력】이 1점이상 남아있을 경우 그 전투중에 한번도 비행상태가 되지 않은 PC와 괴물의 본체는 【생명력】이 [전투에 소비한 난전 라운드 수x3D6]점 감소한다. PC가 기프트를 사용할 때 백의 영역의 인과가 추가로 2개 있는것으로 취급한다.",
"평지. 아무런 효과도 없다.",
],},

    "RT" => {
      :name => "관계표",
      :type => '1D6',
      :table => [
"연심(플러스) / 살의(마이너스)",
"동정(플러스) / 모멸(마이너스)",
"동경(플러스) / 질투(마이너스)",
"신뢰(플러스) / 의심(마이너스)",
"공감(플러스) / 밥맛(마이너스)",
"소중(플러스) / 귀찮(마이너스)",
],},

    "PRT" => {
      :name => "부모마음표",
      :type => '1D6',
      :table => [
"귀엽다(플러스) / 건방지다(마이너스)",
"기대(플러스) / 위협(마이너스)",
"자랑(플러스) / 수치(마이너스)",
"애정(플러스) / 무관심(마이너스)",
"유용(플러스) / 걱정(마이너스)",
"과보호(플러스) / 집착(마이너스)",
],},

    "FT" => {
      :name => "펌블표",
      :type => '1D6',
      :table => [
"운명의 수레바퀴가 회전한다. 각각의 영역의 인과를 적->청->녹->백->적으로 옮긴다.",
"동료에게 민폐를 끼친다. 자신 이외의 PC전원은 【생명력】이 1점 감소한다.",
"이 실패는 나중에 빌미가 될지도 모른다. 자신의 【생명력】이 1D6점 감소한다.",
"너무 큰 실패에 다른 사람들의 태도가 변한다. 자신에 대해 가장 높은 【마음】을 가지고 있는 캐릭터 전원의 【마음】의 속성이 반전한다.",
"마음에 큰 동요가 생긴다. 자신에 속성에 대응한 상태이상을 획득한다.\n(흑->절망, 적->분노, 청->두려움3, 녹->타락, 백->수치)",
"주변에 활기가 사라진다. 운명의 수레바퀴에서 흑의 영역 이외의 인과를 모두 1개씩 제거한다.",
],},

    "BT" => {
      :name => "휴식표",
      :type => 'D66',
      :table => [
[11, "토착 괴물이 습격해왔다! 어떻게든 격퇴했지만 부상을 입었다. 자신은 1D6점 데미지를 입는다."],
[12, "미녀의 목욕을 훔쳐보고 말았다. 1D6을 굴려 1~2라면 「타락」, 3~4라면 「수치」, 5~6이라면 「중상1」의 상태이상을 획득한다."],
[13, "욕심이 강한 상인을 만났다. 이 신에 등장한 모든 캐릭터는 아이템을 살 수 있다. 단, 평소의 가격보다 1 높다."],
[14, "자신의 과거의 이야기를 한다. 어째서 이런 얘기가 됐지? PC 중에서 자신에 대해 가장 높은 【마음】을 가지고 있는 PC 전원은 【마음】의 속성이 반전한다."],
[15, "주변의 공기가 변한다. 운명의 수레바퀴가 움직일 예감! 각각의 영역의 인과를 적->청->녹->백->적으로 옮긴다."],
[16, "당신은 무심코 노래를 부른다. 어느샌가 모두가 그 노래에 집중하고 있었다. 흑의 영역 이외의 원하는 인과 1개를 다른 영역으로 옮긴다."],
[22, "〈절계〉의 바깥 세계의 친구를 떠올린다. 모두 건강하게 지내고 있을까?  이 PC가【일상】의 판정에 성공하면 자신의 상태이상 1개를 회복하거나 흑의 영역의 인과를 하나 제거할 수 있다."],
[23, "기묘한 상인을 만났다. 이 신에 등장한 모든 캐릭터는 아이템을 살 수 있다."],
[24, "말하는 동물에게 부탁을 받는다. 동물들도 이 신화재해로 고생하고 있는듯 하다. 이 PC는 「이 괴물의 본체의 【생명력】을 0으로 한다」라는 추가의 【임무】를 받는다. 이 【임무】를 달성하면 추가로 경험치를 20점 받는다."],
[25, "멋진 꿈을 꾼다. 이 표를 굴린 PC는 자신의 PC 이외의 캐릭터 1명에 대한 【마음】이 1점 상승한다."],
[26, "소중한 사람에게서 당신을 걱정하는 문자를 받았다. 뭐라고 답장하지? 이 표를 굴린 PC는 【일상】의 판정에 성공하면 자신의 상태이상을 1개 회복하거나 자신이 가진 【마음】의 체크를 1개 해제한다."],
[33, "친절한 상인을 만났다. 이 신에 등장한 모든 캐릭터는 아이템을 살 수 있다. 단, 평소의 가격보다 1 낮다.(1 미만은 되지 않는다.)"],
[34, "무기의 정비를 한다. 이 표를 굴린 PC는 【일상】의 판정에 성공하면 이 세션 동안 무기 1개의 위력을 1점 상승시킬 수 있다."],
[35, "마지막으로 쇼핑을 했을때 잔돈을 더 받은걸 깨달았다. 코인을 1개 획득한다."],
[36, "식사를 하면서 동료들과 떠든다. 이 신에 등장해서 식사를 한 PC 전원은 자신이 가진 【마음】의 체크를 1개 해제한다."],
[44, "잠깐 잠들었는지 이상한 꿈을 꾼다. 이 표를 굴린 PC는 【영력】의 판정에 성공하면 원하는 예언카드 1장의 【진실】을 볼 수 있다."],
[45, "양아치들에게 얽힌 이성을 발견한다. 이 표를 굴린 PC가 【무용】의 판정에 성공하면 그 NPC는 이 표를 굴린 PC에 대한 【마음】을 1점 획득한다. 이 NPC를 협력자로 한다면 이 표를 굴린 PC가 이름과 관계를 자유롭게 정한다."],
[46, "기분좋은 바람이 분다. 운명이 당신을 도와주는듯한 기분이 든다. 원하는 영역에 인과를 1개 배치한다."],
[55, "눈을 뜨면 머리맡에 선물이 있다. 누굴까……? 이 표를 굴린 PC는 「랜덤 아이템표」를 사용한다."],
[56, "곤란해하는 신화생물을 도와줬다. 이 표를 굴린 PC는【일상】의 판정에 성공하면 다음 이동판정을 자동으로 성공한다.(달성치는 6으로 한다)"],
[66, "부모신이 당신에게 이야기하고 있다. 부모자식간의 대화다. 이 표를 굴린 PC는 【일상】의 판정에 성공하면 자신의 부모신에 대한 【마음】이나 부모신의 자신에 대한 【마음】중 하나를 1점 상승시킨다."],
],},

    "FWT" => {
      :name => "치명상표",
      :type => '1D6',
      :table => [
"절망적인 공격을 받는다. 이 캐릭터는 사망한다.",
"고통의 비명을 지르고 무참하게 무너진다. 이 캐릭터는 행동불능이 되고 흑의 영역의 인과가 1 증가한다.",
"공격을 받은 무기가 부숴지고 적의 공격에 직격당한다. 이 캐릭터는 행동불능이 되고 아이템란 에서 무기 하나를 파괴한다.",
"강렬한 일격을 받아 기절한다. 이 캐릭터는 행동불능이 된다.",
"의식은 있지만 일어날 수 없다. 이 캐릭터는 행동불능이 되고 다음 신이 되면 【생명력】이 1점으로 회복된다.",
"기적적으로 버틴다. 【생명력】이 1점으로 회복된다.",
],},
    "BRT" => {
      :name => "전과표",
      :type => '1D6',
      :table => [
"코인을 1개 획득한다.",
"코인을 1D6개 획득한다.",
"원하는 영역에 인과를 1개 배치한다.",
"흑의 영역의 인과를 1개 제거한다.",
"「랜덤 아이템표」를 1번 사용한다.",
"PC 전원은 인물란의 체크를 1개 해제한다.",
],},

    "RIT" => {
      :name => "랜덤아이템표",
      :type => '2D6',
      :table => [
"「갑옷」을 1개 획득한다.",
"「단서」를 1개 획득한다.",
"「패션 아이템」을 1개 획득한다.",
"「수호부적」을 1개 획득한다.",
"「감로」을 1개 획득한다.",
"「식량」을 1D6개 획득한다.",
"「향」을 1개 획득한다.",
"「공물」을 1개 획득한다.",
"「영약」을 1개 획득한다.",
"「진수성찬」을 1개 획득한다.",
"「폭탄」을 1개 획득한다.",
],},

    "WT" => {
      :name => "부상표",
      :type => '1D6',
      :table => [
"자신의 【생명력】이 1D6점 감소한다.",
"코인을 1D6개 잃는다.",
"흑의 영역에 인과를 1개 배치한다.",
"「두려움3」의 상태이상을 획득한다.",
"「중상3」의 상태이상을 획득한다.",
"자신의 인물란의 가장 높은【마음】1개가 1점 감소한다. ",
],},

    "NMT" => {
      :name => "악몽표",
      :type => '1D6',
      :table => [
"절망의 어둠에 시야를 차단당한다. 등뒤에 괴물의 기척이 느껴진다고 생각했을때는 늦었다. 비열한 공격이 당신을 덮친다. 원하는 능력치로 판정해 실패하면 사망한다.",
"절망의 어둠 속, 비통한 절규가 들려온다. 사건의 피해자들일까. 당신은 구하지 못했다. 【일상】의 판정에 실패하면 「절망」의 저주를 받는다.",
"절망의 어둠 속에서 괴물의 웃음소리가 메아리친다. 그것은 비웃는 소리였다. 괴물이나 동료들…… 무엇보다 자신에 대한 분노가 끓어오른다. 【일상】의 판정에 실패하면 「분노」의 저주를 받는다.",
"절망의 어둠 속에서 혼자 남겨졌다. 아무도 당신을 눈치채지 못한다. 고독에 견디면서 어떻게든 일상으로 귀환했지만…… 그 때의 공포를 극복하지 못했다. 【일상】의 판정에 실패하면 「두려움3」의 저주를 받는다.",
"절망의 어둠에서 귀환한 당신을 기다리고 있는건 전보다 나은것이 없는 일상이었다. 당신이 임무에 실패해도 세계는 변하지 않는다. 그렇다면, 더이상 당신은 그런 무서운 일을 당할 필요가 없지 않을까? 【일상】의 판정에 실패하면 「타락」의 저주를 받는다.",
"절망의 어둠 속에서 필사적으로 도망쳤다. 등뒤에서 동료의 목소리가 들린듯한 기분이 든다. 하지만, 당신은 돌아볼 수 없었다. 【일상】의 판정에 실패하면 「수치」의 저주를 받는다.",
],},

    "TGT" => {
      :name => "목표표",
      :type => '1D6',
      :table => [
"악의. PC 중에서 가장 【생명력】이 낮은 PC 1명을 선택한다. 가장 낮은 【생명력】인 사람이 여럿 있을 경우, 그 중에서 GM이 자유롭게 선택한다.",
"교활. 가장 숫자가 높은 패러그래프에 있는 PC 1명을 선택한다. 전원이 장외에 있을 경우, 장외에 있는 PC 전원을 목표로 선택한다.",
"비도. PC 중에서 가장 【무용】랭크가 낮은 PC 1명을 선택한다. 가장 낮은 랭크를 가진 사람이 여럿 있을 경우, 그 중에서 가장 낮은 모드를 가진 사람을 1명 선택한다. 모드도 같을 경우, 그 중에서 GM이 자유롭게 선택한다.",
"견실. PC 중에서 가장 【기술】랭크가 낮은 PC 1명을 선택한다. 가장 낮은 랭크를 가진 사람이 여럿 있을 경우, 그 중에서 가장 낮은 모드를 가진 사람을 1명 선택한다. 모드도 같을 경우, 그 중에서 GM이 자유롭게 선택한다.",
"호쾌. PC 중에서 가장 【무용】랭크가 높은 PC 1명을 선택한다. 가장 높은 랭크를 가진 사람이 여럿 있을 경우, 그 중에서 가장 높은 모드를 가진 사람을 1명 선택한다. 모드도 같을 경우, 그 중에서 GM이 자유롭게 선택한다.",
"교활. 가장 숫자가 낮은 패러그래프에 있는 PC 1명을 선택한다. 전원이 장외에 있을 경우, 장외에 있는 PC 전원을 목표로 선택한다.",
],},

    "CST" => {
      :name => "制約表",
      :type => '1D6',
      :table => %w{
短命
誘惑
悪影響
束縛
喧嘩
干渉
},},

    "GCVT" => {
      :name => "ギリシャ神群試練表",
      :type => '1D6',
      :table => %w{
山の向こうから一つ目の巨人、サイクロプスがこちらを見ている。岩を投げてきた！1D6点のダメージを受ける。
水音に目を向けると、アルテミスが泉で水浴びをしていた。美しい……あ、気づかれた？自分が男性なら、「重傷2」の変調を受ける。自分が女性なら、「恥辱」の変調を受ける。
海を渡ろうとすると、海が渦巻き乗った船が引き寄せられていく。中心にいるのは怪物カリュブディスだ。このままだと、船ごと飲み込まれてしまう。［青の領域にあるインガの数］点ダメージを受ける。
デュオニソスの女性信者、マイナスたちに取り囲まれる。彼女たちは完全に酔っ払っており、話は通じない上、酒を飲めと強要してくる。【生命力】が1点回復し、「堕落」の変調を受ける。
巨大な天井を支えている巨人と出会う。巨人は「少しの間、支えるのを代わってくれないか？」と頼んでくる。断りにくい雰囲気だ……。【愛】で判定を行う。失敗すると、そのセッションの間、所持品の欄が一つ使えなくなる。その欄にアイテムが記入されていれば、それを捨てること。
「あなた最近、調子に乗ってない？」アフロディーテに難癖をつけられた。「自分のことだけ見てればいいんじゃない？」鏡に映る自分が、とても美しく思えてきた。自分への【想い】が2点上昇し、それ以外の人物欄のパトスすべてにチェックを入れる。
},},

    "YCVT" => {
      :name => "ヤマト神群試練表",
      :type => '1D6',
      :table => %w{
空が急に暗くなる。太陽がどこにも見えない。もしかして、アマテラスが隠れてしまったのか？黒の領域にインガを一つ配置する。
いつのまにか、黄泉国に迷い込んでしまっていた。周囲は黄泉軍に取り囲まれている。どうにかして、逃げなくては！移動判定を行う。失敗すると、3点のダメージを受け、もう一度「試練表」を振る。
目の前の海はワニザメでいっぱいだ。この海を渡らなければ、目的地にはたどり着けないのに。青の領域のインガを二つ取り除くか、自分が2D6点のダメージを受けるかを選ぶ。
「みんなー楽しんでるー!?」ここはウズメが歌い踊るライブ会場だ。どうしよう、目的を忘れそうなほど楽しい！自分は、自分の属性のインガを一つ取り除くか、「堕落」の変調を受けるかを選ぶ。
「龍の首の珠を取るのを手伝ってくれませんか？そうしたら、船に乗せてさしあげます」平安貴族のような格好をした男が話しかけてくる。手伝うしかないようだ。「重傷1」の変調を受ける。
海岸でいじめられている亀を助けたら、海の中の宮殿につれてきてくれた。トヨタマヒメが現れ、盛大にもてなしてくれる。あっという間に、夢のような時間が過ぎていく。でも、そろそろ行かなくては。【日常】で判定する。失敗すると、自分の年齢を6D6歳増やし、「絶望」の変調を受ける。
},},

    "ECVT" => {
      :name => "エジプト神群試練表",
      :type => '1D6',
      :table => %w{
大蛇アペプが今にも目の前の空で輝く太陽を、飲み込もうとしている！止めなくては！【武勇】で判定する。失敗すると、黒の領域にインガを二つ配置する。
気がつけば、魂が羽の生えたバーだけになって、空を飛んでいた。早く肉体に戻らなくては。【霊力】で判定する。自分の【生命力】を1D6点減少し、もう一度「試練表」を振る。
ぐつぐつと沸き立つ湖と、流れる火の川が見える。目的地は、この川を越えた先にある。【技術】で判定する。失敗すると、炎タグのついた2D6点のダメージを受け、黒以外の領域のインガが一つずつ取り除かれる。
冥界ドゥアトの番人たちが、目の前に現れた。と畜場より来る吸血鬼、下半身の排泄物を喰らうものが近づいてくる。ここは冥界なのか、それとも、やつらが地上に這い出してきたのか。自分は、「重傷1」の変調を受けるか、「恥辱」の変調を受けるかを選ぶ。
目の前にアヌビスがいる。アヌビスは天秤を掲げて、心臓を要求してくる。「お前の罪を数えろ」【日常】で判定を行う。失敗すると、【活力】が0点になる。この効果によって【生命力】の現在値が最大値を超えた場合、最大値と同じ値に調整する。
獅子頭の神、シェセムが、悪人の頭を砕いて、死者のためのワインにしている。悪人と見なされれば、頭をもがれてしまうだろう。【日常】で判定を行う。失敗すると、「重傷2」の変調を受ける。
},},

    "CCVT" => {
      :name => "クトゥルフ神群試練表",
      :type => '1D6',
      :table => %w{
新聞記者たちが忙しく行き来しているオフィスにいる。ここは、新聞社アーカムアドバタイザーの編集部だ。「君が大きなニュースを持っていると聞いたんだけれど」記者の一人が尋ねてくる。自分の【真実】が公開されていなければ、「臆病1」の変調を受ける。
魚の顔と鱗に覆われた身体をもつ、ディープワンに取り囲まれる。あなたが女性ならば、彼らのすみかに連れ去られてしまう。男性ならば、暴力を振るわれ、1D6点のダメージを受ける。女性なら、衣服を奪われ、「恥辱」の変調を受ける。
ここはどうやら夢の中らしい。目の前にクトゥルフがいる。「余になんの用だ。余を目覚めさせる気なら、容赦はしない」寝ぼけ眼のくせに、クトゥルフは怒っているようだ。「絶望」の変調を受ける。
地下のもぐり酒場で一息つけた……と思ったら、トンプソン機関銃を構えた男たちが飛び込んできた。マフィアの抗争だ！4点のダメージを受ける。
古ぼけた本を手に入れた。どうやら、魔導書のようだ。読むと正気を失う可能性もあるが、力が手に入る可能性も高い。【霊力】のランクがA以上なら、好きな領域にインガを二つ配置する。そうでない場合、「絶望」と「臆病2」の変調を受ける。
なんの変哲も無い民家にいる。アーカムの静かな風景が……ああ、窓に！窓に！黒の領域にインガを一つ配置する。
},},

    "NCVT" => {
      :name => "北欧神群試練表",
      :type => '1D6',
      :table => %w{
美しい乙女が告げる。「あなたはエインヘリアルたる資格がある」どうやら、戦乙女ヴァルキュリャに見初められたらしい。彼女たちは、戦死した者の魂を連れていくのだが。自分は、戦乙女から【想い】を2点獲得する。この【想い】の関係はマイナスの「殺意」となる。
雄叫びと共に現れたのは、獣の皮を被った屈強な戦士たち、ベルセルクだった。手に手に斧を構え、こちらに向かってくる！【武勇】で判定を行う。失敗すると、2D6点のダメージを受ける。
オーディンの神子、エインヘリアルたちの宴会に紛れ込んでしまった。山のように積まれたご馳走を好きに食べていいと思ったら、「勝負だ！」という声。食べ比べを挑まれている。神子としては、負けるわけにはいかない。【日常】で判定を行う。失敗すると、「恥辱」の変調を受ける。
「ここは我々の土地だ。ただで通れると思っているのか？」ドヴェルグが行く手を塞ぎ、神貨を要求してくる。彼らはがめついことで有名だ。神貨を2点支払う。支払わない場合、自分の【生命力】を1点減少して、もう一度「試練表」を使用する。
「このまま冒険を続けても簡単すぎるんじゃないか？」ロキが話し掛けてきた。気がつくと君は狼の姿に変わっていた。このセッションの間、自分に「獣」のタグがつき、【愛】のランクが1段階低くなる（Dは変化しない）。
巨人が話し掛けてくる。「お前に力をやってもいい。代わりに、片目か、片腕をよこせ」オーディンは片目を差し出して、知恵を手に入れた。嘘ではないだろうが……。【生命力】を3D6点減少することで、好きな領域にインガを二つ配置できる。減少しなかった場合、「臆病1」の変調を受ける。
},},

    "DGVT" => {
      :name => "ダンジョン試練表",
      :type => '1D6',
      :table => %w{
照明が切れてしまい、暗闇の中に放り出される。前が見えない。白の領域からインガを一つ取り除く。
罠だ！こちらに向かって、巨大な岩が転がって来る！【技術】で判定する。失敗すると、2D6点のダメージを受ける。
宝箱発見。罠がないかを慎重に調べてみよう。【技術】で判定する。成功すると、1神貨を獲得する。失敗すると、「憤怒」と「恥辱」の変調を受ける。
謎解きが必要な部分に迷い込む。この謎を解かなければ、罠を無理矢理突破しなければならない。【頭脳】で判定を行う。失敗すると、「絶望」の変調を受け、1D6点のダメージを受ける。
粘液が飛び散る部屋に入ってしまった。まずい、何でも溶かす酸だ！自分が装備しているアイテムの中から一つを選ぶ。選んだアイテムを破壊する。【食料】を選んだ場合は、すべての【食料】を破壊する。
怪物たちのすみかに迷い込んでしまったようだ。怪物が一斉に襲ってくる！【武勇】で判定を行う。失敗すると、2D6点のダメージを受ける。
},},

    "DAVT" => {
      :name => "日常試練表",
      :type => '1D6',
      :table => %w{
仲間と移動していると、一般人の友達と偶然出会ってしまう。今何をしているかを聞かれたので、なんとかごまかす。自分に対して【想い】の値を持っているPC全員の属性が反転する。
仕事や勉強を催促する電話がかかってきた。今はそれどころじゃないんだって！「憤怒」の変調を受ける。
ふと、見たかったテレビ番組を見逃していたことに気づいてしまう。録画もしてない。ちょっと凹む。自分の属性と同じ領域にあるインガを一つ取り除く。
警官に捕まって、職務質問を受ける。ちょっと言えない理由で、急いでいるんですけど。黒の領域にインガを一つ配置する。
自分の格好や言動が浮いていたらしい、自分を噂するひそひそ話が聞こえてきてしまう。「恥辱」の変調を受けるか、【食料】以外のアイテムを1つ破壊する。
乗りたかった電車やバスに乗り遅れる。仕方ないから、走るか。移動判定を行う。失敗すると、「堕落」の変調を受け、もう一度「試練表」を使用する。
},},

    "PRCT" => {
      :name => "挑戦テーマ表【武勇】",
      :type => '1D6',
      :table => %w{
腕相撲
喧嘩
度胸試し
レスリング
狩り
武勇伝自慢
},},

    "TCCT" => {
      :name => "挑戦テーマ表【技術】",
      :type => '1D6',
      :table => %w{
織物
戦車レース
マラソン
アクションゲーム
射的
資格自慢
},},

    "INCT" => {
      :name => "挑戦テーマ表【頭脳】",
      :type => '1D6',
      :table => %w{
パズル
謎かけ
チェス
筆記試験
禅問答
学歴自慢
},},

    "PSCT" => {
      :name => "挑戦テーマ表【霊力】",
      :type => '1D6',
      :table => %w{
詩作
動物を手なずける
北風と太陽
絵画
演奏
のど自慢
},},

    "LVCT" => {
      :name => "挑戦テーマ表【愛】",
      :type => '1D6',
      :table => %w{
ナンパ勝負
誰かからより愛される
美人コンテスト
ティッシュ配り
借り物競争
恋愛自慢
},},

    "DACT" => {
      :name => "挑戦テーマ表【日常】",
      :type => '1D6',
      :table => %w{
料理
大食い
呑み比べ
倹約生活
サバイバル
リア充自慢
},},

  }

  setPrefixes(['R[A-DS].*'] + @@tables.keys)
end
