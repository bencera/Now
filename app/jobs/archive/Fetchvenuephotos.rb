# -*- encoding : utf-8 -*-
class Fetchvenuephotos
  @queue = :fetchvenuephotos
  def self.perform(subscription)
    Rails.logger.info("Doing venue photos fetch")
    #New York (285)
    venue_ny = ["22481", "3002301", "1195657", "66348", "36714", "1349451", "14036", "7577260", "5897884", "1524333", "262783", "48359", "482445", "97445", "60729", "119764", "9139452", "3002095", "20843", "197748", "143112", "2669564", "6618680", "3437211", "8885", "2443593", "195046", "514330", "3298616", "157648", "71389", "2637871", "3000712", "1161978", "1420070", "1495", "2962165", "3973841", "26929", "71784", "1556371", "308405", "49140", "889345", "864422", "2999916", "26890", "26447", "76011", "3066", "1359397", "369480", "56401", "3238828", "82301", "1506994", "796471", "1206", "93352", "41415", "94774", "1346256", "13765", "12318445", "59615", "45767", "105450", "2096177", "12971029", "190583", "1519", "264047", "10842", "18745", "54312", "4152", "2514249", "107729", "9721", "72396", "2218510", "34785", "22187", "241945", "2133119", "3001475", "17215", "204075", "3041723", "687485", "3350014", "3001881", "2113451", "949574", "12935", "522711", "2082352", "3002869", "1458018", "1945166", "777858", "200569", "294684", "125042", "14296204", "621936", "528007", "1420514", "435932", "42733", "14383688", "30699", "14318378", "33992", "118835", "197728", "156996", "15780161", "66385", "30331", "370298", "13372", "364029", "553692", "2403743", "29850", "13844", "14324245", "23023", "24223", "21565", "68373", "101939", "6321556", "105115", "6593370", "2572586", "374881", "2058953", "192079", "3447859", "2047255", "19076", "350520", "48688", "9051145", "2054107", "456729", "3250791", "3079812", "26875", "299456", "3001706", "922795", "9470", "68598", "2048758", "1273608", "93716", "17900", "22313", "4056046", "3000511", "3002892", "15151992", "375335", "17465", "2295813", "145967", "8495708", "1727398", "1296762", "10560369", "2872262", "3908491", "2846220", "820295", "15768021", "412895", "126201", "15908406", "15661999", "3602873", "3000505", "375778", "7033", "364343", "14891200", "521678", "12909734", "54373", "612036", "5060277", "789020", "16642522", "16657122", "3212287", "16656606", "2598644", "538649", "18295", "4853903", "54226", "17254492", "3785956", "609189", "152078", "5265217", "14767653", "320111", "1057890", "30061", "4647142", "3793094", "15707253", "12515613", "17816939", "996358", "2596499", "13458442", "44520", "815202", "56414", "3386555", "16433873", "11381696", "12272", "18221682", "34052", "362105", "11196466", "18347776", "18237114", "489081", "15529463", "724759", "677376", "3385467", "2371720", "505090", "18863190", "18932785", "59736", "253515", "1275807", "14006", "3503020", "13455", "493791", "8921617", "156642", "17063638", "221699", "1724266", "19791019", "3446504", "17834", "3357992", "7421", "20155647", "19912303", "752930", "5333053", "819205", "16933382", "20941395", "19139", "839337", "308227", "1200", "99636", "2825018", "8054509", "22095086", "268255", "16684350", "746", "144229", "3237667", "746143", "40011", "23600329", "17479498", "14468", "9200078"]
    #SF (224)
    venue_sf = ["493962", "2184046", "47288", "6472735", "2408170", "1331", "195889", "87148", "2998637", "4354", "37039", "147692", "1615", "274473", "5500", "1484", "3001584", "1498", "1647", "94668", "1168186", "14883", "2619154", "34998", "13613", "1572", "187324", "3000292", "493535", "185875", "2203654", "896", "1362", "450867", "281523", "4447", "917", "6149", "1292", "1056", "156517", "1593", "13432", "19120", "13044", "396635", "2469936", "155", "953", "346876", "5703602", "134182", "6522", "2222848", "2178679", "4589", "1190", "13918469", "3159300", "13905", "371141", "50472", "10157", "952", "12981", "879", "26933", "7497", "1749791", "7689", "2314253", "1036", "11108769", "5144903", "1731496", "6427", "401", "182", "19", "804", "473394", "2084436", "2932071", "565908", "1542", "1203543", "7642901", "547347", "947", "2004397", "6127", "220010", "3080388", "676111", "3914856", "15994913", "366217", "15691787", "686499", "78620", "566440", "3081888", "487943", "16519015", "4418698", "17242922", "17486901", "181983", "1260198", "306836", "1082", "13543", "938", "26962", "93123", "158162", "50101", "463341", "2908586", "18344429", "1276046", "18489845", "27", "4029080", "1369067", "192364", "18477773", "5567187", "8215914", "3173287", "6811063", "5951518", "221414", "536", "334302", "77740", "604156", "3002937", "7406", "107901", "1721", "4671402", "15599", "364263", "1630", "1389", "47832", "20103638", "1373091", "2349378", "20339970", "986212", "1020411", "11452403", "380312", "8269862", "2824338", "10834", "910270", "2123140", "3250432", "20742982", "11681445", "10807", "20758218", "298105", "15684533", "1450", "3003251", "21131257", "21126198", "1455048", "14650171", "1261393", "17219441", "15020", "1323638", "55995", "3001838", "689729", "59280", "395938", "700", "443", "1356986", "22206406", "5991166", "773824", "14165", "21353128", "112437", "647397", "967", "1287393", "922", "954062", "714", "465897", "8391667", "23256205", "164090", "5397864", "18115078", "547930", "457608", "3001795", "13864920", "23506109", "790698", "209437", "1316", "7677598", "66", "24406651", "205479", "2115", "1099634", "315386", "358257", "2082701", "327469", "25412554", "25766366", "531"]
    #LA (125)
    venue_la = ["750571", "31201", "4169", "41999", "1730261", "742947", "70014", "329392", "16430532", "3959862", "457739", "3000453", "9920157", "1870957", "1313001", "275424", "1136004", "14252948", "3001340", "3488737", "3000873", "3043902", "15013904", "3267026", "496162", "1794433", "82215", "3828618", "7116", "1712776", "438384", "1561246", "21651984", "1605517", "100768", "48085", "19404", "91138", "48711", "306614", "6273578", "292802", "6072125", "152930", "365553", "19143517", "3981165", "571375", "93535", "14784", "19757397", "31460", "82181", "48039", "1067508", "2669213", "8032017", "61844", "31840", "99782", "231693", "3479440", "3120908", "895650", "2260615", "16050908", "3177467", "16057627", "37422", "10218146", "22313958", "1022934", "166453", "84879", "13957", "167949", "6850", "342650", "3885582", "435254", "207639", "3824034", "26872", "2430636", "3003060", "1987281", "93117", "308532", "2223712", "49953", "3479772", "3002858", "2342272", "931155", "3085286", "268984", "264271", "220099", "2999944", "3997226", "275277", "1505655", "485441", "285901", "108319", "274552", "89751", "455017", "22420", "675798", "3449313", "117015", "4011162", "7853689", "1457", "1276", "7191", "5951486", "358760", "2407", "1639313", "5062780", "5147002", "311022", "21065030"]
    #London (160)
    venue_ln = ["110531", "103703", "163636", "48051", "70178", "229305", "139674", "1407973", "23320", "1795839", "14244275", "1241986", "16199454", "1281748", "1919893", "14703316", "256904", "11556008", "141653", "840843", "97451", "9763745", "152132", "25619", "267038", "50998", "378432", "674144", "18290", "238202", "3000382", "252353", "609357", "316899", "124147", "1046973", "399001", "120966", "442279", "38990", "532396", "1293847", "117482", "15649406", "3008624", "2575876", "53354", "20266", "2013432", "79329", "930824", "3025528", "21173", "1633429", "476584", "382803", "16608495", "1165359", "16966", "533619", "1919780", "16993901", "1822110", "9086517", "5345556", "195344", "5484", "6990569", "212204", "136411", "32202", "20250", "29131", "25544", "97537", "16602817", "17584838", "312872", "17450462", "111592", "17455826", "10707266", "17770635", "616431", "498060", "105738", "74627", "243224", "391586", "14291972", "181186", "75002", "2059042", "1408830", "40971", "11639911", "75893", "19061175", "5678451", "5886173", "3434706", "1415832", "76068", "1648837", "19589449", "23325", "2197347", "18303915", "96373", "19879748", "231623", "1284144", "2592", "14982518", "15677729", "20838", "243434", "132167", "81697", "6979983", "37672", "192947", "59156", "21857221", "518190", "22322798", "69472", "1838616", "2457609", "10719199", "8964511", "266375", "3485523", "228200", "5664734", "584290", "330780", "2685813", "23730165", "23744173", "15749015", "23570105", "138062", "163292", "3980538", "39882", "40484", "1721568", "89352", "373832", "16139", "23093247", "92890", "25201197", "1882518", "25343932", "896772", "114612", "25225715", "25515644"]
    #Paris (130)
    venue_pa = ["1630554", "1454213", "52629", "1835542", "69738", "16566", "6470", "3296042", "239486", "2415828", "202626", "325719", "566284", "2268969", "15396451", "1695801", "7971", "651459", "447991", "183169", "495617", "1137419", "14326771", "403893", "1861699", "280326", "843265", "561557", "14883813", "6489", "8299", "39456", "5372123", "1521533", "12962", "1174427", "29052", "520246", "517558", "228043", "429587", "14704732", "984932", "1351110", "290297", "117806", "576000", "1331753", "437315", "1503859", "200443", "225187", "1073349", "902224", "756545", "11635424", "1437238", "70377", "533818", "2066191", "563807", "1807102", "17375661", "1587133", "10941470", "281620", "400898", "266336", "3398149", "2200275", "5555825", "14969793", "3445319", "2392318", "316949", "626185", "1339240", "4175178", "1229513", "555021", "3549994", "7742063", "660576", "180461", "555012", "419557", "11039323", "1938234", "3689478", "241134", "183850", "95111", "3348790", "4827906", "628205", "985304", "1022323", "8085692", "21132248", "1084340", "860039", "1614616", "574072", "64869", "5189827", "1100128", "149456", "1906646", "432780", "1064780", "365217", "14310125", "2447557", "334406", "14316727", "1230667", "803395", "2593354", "8583777", "24078255", "24227645", "162662", "23287723", "709459", "3061302", "24410674", "454822", "10727381", "1074842", "4072033"]
   
    venue_sp = ["49281", "1336712", "503961", "25411", "8536066", "2749924", "924681", "490958", "16999", "2951259", "141056", "521983", "697", "228608", "1061809", "297730", "10894", "410364", "92090", "130470", "982599", "220798", "215454", "243916", "349975", "546617", "6996311", "498985", "1456045", "2530842", "4544765", "379561", "164665", "271491", "84903", "437908", "272695", "404840", "272526", "5870505", "472214", "1137674", "223244", "367746", "5184188", "1726743", "436687", "972042", "538264", "1136560", "7080360", "232791", "481150", "3358652", "15879947", "172471", "2079217", "717264", "84465", "3002426", "402392", "296370", "432730", "775694", "5934425", "1063504", "332992", "1019350", "1004311", "152582", "1533081", "972837", "1011537", "12874719", "278135", "1388742", "435510", "99871", "462540", "553574", "2554345", "2163827", "7390334", "8484347", "555740", "1791512", "336289", "1258837", "21069677", "885219", "233010", "124945", "6069837", "5756879", "2618361", "2304437", "217789", "13460923", "30206", "433854", "6339860", "1009129", "1899930", "54428", "376530", "1122836", "144353", "984989", "1555659", "3001907", "653589", "763040", "473359", "29121852", "519118", "691226", "201908", "219030", "3002585", "142448", "1138291", "423889", "654098", "260063", "54438", "180987", "596237", "461850", "174988", "586275", "310219", "224415", "970133", "1089107", "1540093", "1064878", "863904", "5616016", "374597", "2695935", "1138812", "957463", "355481", "1602782", "468954", "377430", "3763368", "611022", "466603", "662785", "1974480", "341655", "1428284", "1090160", "361040", "1084761", "1306871", "1866183", "1406753", "579203", "1100975", "3488392", "1371751", "47022", "1442736", "3855932", "646186", "644109", "8597742", "486088", "1623909", "1056496", "5152750", "1098298", "492294", "572439", "1407376", "4579507", "4115936", "6376576", "1033675", "1858856", "2999607", "60793", "952627", "375494", "202346", "13476", "1074673", "642617", "70597", "33156417", "283718", "119639", "2099400", "876143", "28909137", "1033036", "42526262", "281749", "2575492", "335134", "991048", "317085", "355619", "1178246", "1285401", "612622", "1878691", "3003405", "1137454", "481781", "1130895", "620500", "1736805", "124788", "670560", "1230273", "37903526", "491383"]

    venue_ids1 = venue_ny + venue_sf
#    venue_ids2 = venue_la + venue_ln + venue_pa
    venue_ids2 = venue_sp

    $redis.incr("count_venue_ids")

    if $redis.get("count_venue_ids").to_i % 2 == 0
      venue_ids = venue_ids1
    else
      venue_ids = venue_ids2
    end

    venue_ids.each do |venue_id|
      begin
        #access_token = $redis.smembers("accesstokens")[rand($redis.smembers("accesstokens").size)]
        #client = Instagram.client(:access_token => access_token)
        response = Instagram.location_recent_media(venue_id)
        
        #puts "#{Venue.where(:ig_venue_id => venue_id).first.name}"
        response.data.each do |media|
          unless media.location.id.nil?
            unless Photo.exists?(conditions: {ig_media_id: media.id})
              Photo.new.find_location_and_save(media,nil)
            end
          end
        end
      rescue
      end
    end
    Rails.logger.info("finished venue photos fetch")
  end
end