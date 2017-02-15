//
//  Map.swift
//  Whitechapel
//
//  Created by René Dekker on 25/03/2016.
//  Copyright © 2016 Renevision. All rights reserved.
//

import UIKit

func distance(_ pt1:CGPoint, _ pt2:CGPoint) -> CGFloat {
    return hypot(pt1.x - pt2.x, pt1.y - pt2.y)
}

let points: [Int: Array<Array<Int>>] = [
1 : [[182,34]],
2 : [[291,26, 270,38, 205,36, 183,34]],
3 : [[344,28, 316,29, 290,28]],
4 : [[374,46, 374,30, 344,28]],
5 : [[454,27, 374,28]],
6 : [[146,92, 148,68, 170,56, 183,34]],
7 : [[170,84, 170,56], [170,84, 166,116, 145,118, 146,92]],
8 : [[288,99, 268,100, 269,76, 270,38]],
9 : [[310,82, 313,66, 316,28], [269,76], [308,98, 287,98]],
10 : [[340,97, 309,98], [378,97, 376,64, 374,46]],
11 : [[343,65, 314,64], [376,64]],
12 : [[422,65, 376,65], [472,65, 482,45, 454,28]],
13 : [[474,86, 472,66]],
14 : [[504,103, 478,110, 473,86]],
15 : [[534,99, 530,70, 482,45]],
16 : [[561,91, 556,67, 531,69], [560,91, 566,116, 542,122, 534,98]],
17 : [[570,64, 556,66]],
18 : [[645,66, 600,67, -582,66, 570,64]],
19 : [[681,90, 654,109, 646,67], [714,70, 670,67, 646,67]],
20 : [[722,88, 714,70]],
21 : [[826,62, 788,78, 770,89, 728,104, 722,88]],
22 : [[862,104]],
23 : [[927,70, 912,28, 864,46, 826,62], [882,97, 862,102]],
24 : [[120,118, 122,63, 149,68], [120,118, 146,116]],
25 : [[142,143, 144,117, 141,143, 122,148, 120,118, 141,143, 160,160, 168,115]],
26 : [[196,112, 204,38, 194,112, 167,116, 195,112, -266,106, 268,100]],
27 : [[228,146, 190,153, 196,112, 228,147, 270,142]],
28 : [[268,124, 267,106, 268,124, 270,141]],
29 : [[352,149, 312,154, 272,158, 270,140, 352,149, 392,146]],
30 : [[387,125, 391,146, 386,124, 378,97, 387,124, 432,119, 478,110]],
31 : [[472,144, 486,140, 514,131, 504,103]],
32 : [[481,124, 477,110, 480,124, 487,140, 472,144]],
33 : [[527,125, 514,130, 527,125, 542,122]],
34 : [[548,148, 542,122]],
35 : [[571,137, 566,116, 570,137, 577,161, 556,174, 548,148]],
36 : [[580,112, 566,116, 580,112, 594,110, 582,66]],
37 : [[590,152, 577,161]],
38 : [[598,126, 594,110, 598,126, 603,143, 589,152]],
39 : [[619,133, 602,143, 618,134, 654,108]],
40 : [[732,125, 726,104]],
41 : [[778,111, 770,89, 778,110, 786,132, 740,149, 732,125]],
42 : [[808,124, 797,100, 788,78, 808,123, 786,132, 806,124, 844,111, 862,102]],
43 : [[108,192, 110,174, 134,176, -117,154, 121,148, 109,192, 126,200, 147,209, 132,176]],
44 : [[170,174, 132,176, 170,173, 160,160, 141,142, 170,174, -190,164, 190,152]],
45 : [[216,190, 269,182, -266,160, 272,158]],
46 : [[231,164, 196,170, 190,165, 230,165, 266,160]],
47 : [[272,198, 268,180, 272,198, -226,208, 215,190, 272,198, 274,216, 235,220, 227,208]],
48 : [[288,186, 271,158]],
49 : [[375,174, 349,180, 288,185, 374,175, 400,170, -399,166, 392,146]],
50 : [[426,159, 399,166, 425,160, 459,150, 472,144]],
51 : [[440,192, 470,184, 459,150]],
52 : [[483,177, 470,184, 482,177, 478,162, 472,144, 482,178, 496,174, 487,140]],
53 : [[512,198, 496,206, 483,177]],
54 : [[522,164, 496,173, 522,164, 513,131, 522,164, 529,190, -525,192, 511,198], [530,190, 555,174]],
55 : [[571,200, 556,174]],
56 : [[649,188, 634,158, 618,134, 648,188, 616,206, 582,222, 570,199]],
57 : [[701,164, 676,176, 649,188, 700,164, 740,148]],
58 : [[802,164, -794,140, 786,132, 802,164, 744,183, -737,160, 740,149]],
59 : [[152,224, 147,208]],
60 : [[177,234, 159,242, 152,224]],
61 : [[258,233, -242,235, 236,221, 258,233, -276,231, 275,216]],
62 : [[311,232, 302,214, 288,186]],
63 : [[362,226, 358,208, 303,214]],
64 : [[382,202, 358,208, 350,180, 381,202, 410,197, 400,172]],
65 : [[400,233, 430,228, 449,222, 440,192, 400,233, -378,239, 367,242, 362,225]],
66 : [[419,210, 410,196, 419,210, 430,228]],
67 : [[474,214, 448,222, 473,214, 496,206]],
68 : [[547,221, 534,205, 525,192, 548,220, 558,236, 583,221]],
69 : [[612,244, 578,246, 558,236]],
70 : [[650,244, 632,245, 612,244]],
71 : [[688,238, 670,242, 649,244]],
72 : [[730,230, 710,235, 689,238]],
73 : [[748,199, 744,183, 748,199, 808,184, 801,164, 748,199, 752,226, 730,230]],
74 : [[782,221, 752,226, 782,220, 812,217, 808,184]],
75 : [[814,230, 813,216, 782,220], [812,217, 808,183]],
76 : [[836,213, 812,217, 836,212, 862,210, 867,236, 817,244, 814,230]],
77 : [[910,202, 862,211, 910,202, 905,156, -892,107, 882,96]],
78 : [[217,276, 210,256, 198,238, 178,234, 218,276, 192,296, -177,272, 170,272, 158,242]],
79 : [[226,252, 210,258, 226,251, 212,216, 196,170, 226,251, 237,269, 216,276]],
80 : [[276,256, 236,269, 276,256, 320,250, 312,232]],
81 : [[308,285, 292,294, 274,255]],
82 : [[342,246, 320,249, 340,246, 366,243]],
83 : [[402,288, 391,268, 378,240]],
84 : [[446,266, 440,246, 430,228]],
85 : [[532,287, 517,266, 477,296, 464,304, 455,286, 446,267]],
86 : [[535,252, 516,266, 536,252, 556,236]],
87 : [[672,260, 670,243]],
88 : [[714,260, 710,236]],
89 : [[758,268, 756,254, 752,226]],
90 : [[784,250, 756,253, 784,249, 817,244]],
91 : [[789,276, 760,282, 758,266, 790,276, 820,271, 818,244]],
92 : [[822,285, 821,272]],
93 : [[852,266, 820,271]],
94 : [[880,248, 883,263, 852,268, 880,248, -876,235, 867,235]],
95 : [[152,297, 170,272]],
96 : [[202,307, 170,343, 137,316, 150,298, 202,306, 192,296]],
97 : [[252,300, 237,269, 250,300, 212,320, 202,307]],
98 : [[354,314, 338,283, 320,249]],
99 : [[450,314, 436,326, -420,324, 414,310, 402,288, 450,314, 464,304]],
100 : [[481,318, -457,328, 437,326, 480,318, 476,297]],
101 : [[576,298, 544,309, 532,287]],
102 : [[598,303, 578,246, 598,304, 612,349, 592,350, 576,298]],
103 : [[638,300, 632,244]],
104 : [[698,312, 694,278, 689,238, 698,313, 676,315, 672,281, 672,260, 698,313, 720,311, 716,285, 713,260]],
105 : [[740,310, 720,311, 739,310, 764,308, 760,282]],
106 : [[765,322, 764,308]],
107 : [[792,304, 764,308, 793,304, 824,298, 822,286]],
108 : [[798,331, 768,336, 766,322, 798,332, 828,327, 824,300]],
109 : [[854,294, 824,299, 854,294, 888,290, 884,263]],
110 : [[859,322, 828,327, 859,321, 895,316, 888,290]],
111 : [[901,335, 894,316]],
112 : [[76,370, 94,351, -83,340, -112,306, -128,322, 138,316]],
113 : [[114,370, 93,351]],
114 : [[162,356, 170,344, 160,356, 134,392, 114,371]],
115 : [[208,358, -194,346, 177,366, 162,354, 207,358, 228,338, 213,320]],
116 : [[250,360, 229,338]],
117 : [[284,356, 270,332, 252,300, 282,356, 300,380, 310,398, -300,404, 289,410, 268,382, 251,360]],
118 : [[350,376, 310,398, 349,376, -308,309, 318,302, 308,285, 350,376, 377,362, 366,340, 354,316]],
119 : [[386,384, 376,362]],
120 : [[406,344, 377,361, 406,343, 436,326]],
121 : [[428,384, 397,402, 386,384, 428,384, 440,405, 409,423, 398,402, 426,384, 427,371, -388,369, 377,361]],
122 : [[473,356, 454,373, 427,370, 473,355, 492,346, 482,318]],
123 : [[480,376, 454,373, 480,375, 512,380, -498,360, 492,346]],
124 : [[531,346, 510,356, 499,361, 531,346, 520,322, 544,308]],
125 : [[542,380, 513,379, 542,379, 564,384, 591,388, -596,380, 593,352]],
126 : [[560,351, 544,309, 562,350, 565,384, 562,351, 592,352]],
127 : [[627,345, 612,349, 626,346, 620,293, 612,244, 627,346, 644,343, 638,300]],
128 : [[646,366, 644,344]],
129 : [[677,349, 676,315]],
130 : [[724,350, 720,312]],
131 : [[773,378, 771,364, 768,336, 773,377, 776,392, 760,392, 730,390, 724,348]],
132 : [[830,340, 828,326, 830,342, 832,354, 772,363]],
133 : [[834,373, 832,354]],
134 : [[866,350, 833,354, 866,350, 906,354, 902,334]],
135 : [[98,398, 83,384, 76,370, 99,398, 120,410, 134,392]],
136 : [[136,426, 120,410]],
137 : [[164,386, 177,366, 164,386, 148,406, 134,392]],
138 : [[170,428, 148,406], [-138,451, 201,461, 180,474, 150,442, 136,426]],
139 : [[259,426, 228,444, -207,458, 200,461], [289,410]],
140 : [[470,416, 488,402, -489,397, 514,380]],
141 : [[512,416, 493,418, 489,402, 512,416, 534,414, -531,386, 514,379]],
142 : [[608,415, 589,416, 591,387]],
143 : [[624,388, 591,388, 625,388, 612,349, 624,387, 629,416, 607,416, 624,388, 652,389, 646,364]],
144 : [[666,388, 652,388, 666,388, 682,389, 678,349]],
145 : [[706,390, 682,390, 707,390, 700,351, 698,312, 706,390, 732,390]],
146 : [[806,393, 775,392, 805,392, 837,395, 835,374]],
147 : [[911,393, 837,394, 910,394, 906,354]],
148 : [[85,446, 120,410, 86,446, 79,461, -46,439, 82,384]],
149 : [[128,455, 150,442, 128,454, 120,466, 86,446]],
150 : [[304,444, 289,410]],
151 : [[365,448, 344,460, 310,473, 303,444, 364,448, 410,423, 364,448, 350,419, -323,439, 300,404]],
152 : [[404,460]],
153 : [[416,435, 410,422, 416,436, 424,449, 404,460], [424,449, 453,430, 470,416]],
154 : [[466,461, 454,428]],
155 : [[536,459, 534,414]],
156 : [[584,446, 589,416]],
157 : [[602,472, 571,476, 584,445]],
158 : [[632,451, 630,433, 630,417, 632,450, 633,472, 602,473]],
159 : [[664,467, 658,431, 652,390, 665,467, 648,470, 634,471, 664,466, 684,466, 682,390]],
160 : [[707,466, 684,467, 706,466, 710,430, 706,390]],
161 : [[734,437, 732,414, 732,390, 734,436, 755,437, 760,392, 734,437, 733,494, 710,496, 706,466]],
162 : [[74,490, 78,461, 74,490, -134,495, 150,490, 120,466]],
163 : [[162,483, 150,490, 162,483, 180,474]],
164 : [[217,494, 207,458]],
165 : [[344,512, 396,492, 385,470, 404,460]],
166 : [[350,484, 319,496, 310,472, 350,484, 385,470]],
167 : [[412,486, 397,492]],
168 : [[465,498, 452,506, 424,450, 465,498, 480,493, 466,462]],
169 : [[490,522, 480,494]],
170 : [[502,486, 480,494, 501,486, 493,418, 502,486, 510,518, 541,516, 538,457]],
171 : [[616,508, 636,507, 634,471, 616,508, 566,514, 564,494, 572,476]],
172 : [[649,486, 648,470, 648,486, 650,502, -651,528, 662,528, -670,526, 669,499, 665,467]],
173 : [[686,496, 684,468, 686,495, 686,524, 670,526]],
174 : [[182,535, 180,474, 182,535, 224,528, 218,492]],
175 : [[279,543, 270,530, -224,536, 223,529]],
176 : [[320,526, 318,496, 320,526, 324,562, 288,568, 287,557, 279,542]],
177 : [[373,529, 350,538, 345,512, 374,528, 400,523, 396,492]],
178 : [[408,546, 352,561, 349,538, 406,546, 400,522, 407,546, 439,539, 413,486]],
179 : [[447,556, 439,538, 446,556, 414,566, 408,546]],
180 : [[464,537, 452,506, 464,538, 486,576, -506,569, 506,560, 492,523]],
181 : [[512,538, 510,518, 513,538, -515,559, 506,561]],
182 : [[543,553, 541,516]],
183 : [[566,525, 566,514, 565,525, 601,520, -636,517, 636,506, 566,525, -567,537, 567,548, 544,553]],
184 : [[594,565, 593,534, 567,536]],
185 : [[636,530, 636,516, 636,530, 612,532, 594,534, 636,530, 651,526]],
186 : [[637,561, 614,563, 612,532]],
187 : [[662,544, 662,526, 662,543, 663,560, 637,562]],
188 : [[258,572, 231,576, 225,536, 257,572, 288,568]],
189 : [[354,579, 354,562, 353,579, 414,566]],
190 : [[380,600, 332,611, 324,562, 379,600, 420,592, 414,566]],
191 : [[454,582, 421,593, 453,582, 485,576]],
192 : [[572,583, 568,548, 572,583, 598,597, 596,566]],
193 : [[616,580, 615,564, 617,582, 662,578, 662,560, 616,580, 618,600, 598,598]],
194 : [[640,598, 618,600, 640,598, 664,598, 663,578]],
195 : [[687,595, 664,598, 687,595, 686,524]],

]

struct BlockSide : Hashable {
    var from:Node
    var to:Node
    
    var hashValue: Int { return from.hashValue &+ 1023 &* to.hashValue }
}

func ==(lhs: BlockSide, rhs: BlockSide) -> Bool {
    return lhs.from == rhs.from && lhs.to == rhs.to
}

class Map {
    var nodes: Dictionary<Int,Node>
    var allNodes: Array<Node>
    
    func determineNodes()
    {
        let sortedKeys = points.keys.sorted()
        var kind = Node.Kind.dot
        for number in sortedKeys {
            let list = points[number]!
            var mainNode : Node? = nil
            for sublist in list {
                var x = 0
                var lastNode : Node? = mainNode
                for (num) in sublist {
                    if (x == 0) {
                        x = abs(num)
                        kind = num < 0 ? .connect : .dot
                    } else {
                        let pt = CGPoint(x:x, y:num)
                        var newNode = mainNode
                        if (newNode == nil) {
                            newNode = Node(number, pt)
                            mainNode = newNode
                            allNodes.append(newNode!)
                            nodes[number] = newNode!
                        } else {
                            newNode = allNodes.filter({ distance($0.location, pt) < 4 }).first
                            if (newNode == nil) {
                                newNode = Node(number, pt)
                                newNode!.kind = kind
                                allNodes.append(newNode!)
                            }
                            if (newNode != lastNode && newNode != mainNode) {
                                lastNode!.neighbourNodes.insert(newNode!)
                                newNode!.neighbourNodes.insert(lastNode!)
                            }
                        }
                        lastNode = newNode
                        x = 0
                    }
                }
            }
        }
    }
    
    func determineBlock(_ start:Node, to:Node, done:inout Set<BlockSide>) -> Node?
    {
        print(String(format:"block %d", start.number))
        done.insert(BlockSide(from: start, to: to))
        var block: Set<Node> = []
        let circle = CGFloat(2 * M_PI)
        var centre = start.location
        var node = to
        var bearing = atan2(to.location.y - start.location.y, to.location.x - start.location.x);
        while (node != start) {
            if (node.kind == .number) {
                block.insert(node)
                centre.x += node.location.x
                centre.y += node.location.y
                print(String(format:"  found %d", node.number))
            }
            var best = circle
            var bestNode = start
            for next in node.neighbourNodes {
                let nextBearing = atan2(next.location.y - node.location.y, next.location.x - node.location.x)
                let diff = (nextBearing - bearing + 1.5 * circle).truncatingRemainder(dividingBy: circle)
                if (diff > 0.001 && diff < best) {
                    best = diff
                    bestNode = next
                }
            }
            done.insert(BlockSide(from: node, to: bestNode))
            node = bestNode
            bearing = (bearing + best + 1.5 * circle).truncatingRemainder(dividingBy: circle)
        }
        if (block.isEmpty || block.count > 20) {
            // there is no point in adding the block if it only contains the start node
            // also, avoid storing the single large block that lies outside all nodes
            return nil;
        } else {
            block.insert(start)
            centre.x /= CGFloat(block.count)
            centre.y /= CGFloat(block.count)
            let alleyNode = Node(0, centre)
            alleyNode.kind = .alley
            alleyNode.neighbourNodes = block
            return alleyNode
        }
    }

    func determineBlocks()
    {
        var done: Set<BlockSide> = []
        var alleys: Set<Node> = []
        for node in nodes.values {
            for neighbour in node.neighbourNodes {
                if (!done.contains(BlockSide(from:node, to:neighbour))) {
                    if let alley = determineBlock(node, to: neighbour, done:&done) {
                        alleys.insert(alley)
                    }
                }
            }
        }
        for alley in alleys {
            for node in alley.neighbourNodes {
                node.neighbourNodes.insert(alley)
            }
        }
    }

    func reachable(from:Node, traversable:Set<Node.Kind>) -> Set<Node> {
        var result: Set<Node> = [];
        var examined = Set([from])
        var todo = Set(from.neighbourNodes)
        while let node = todo.first {
            todo.remove(node)
            if !examined.contains(node) {
                examined.insert(node)
                if node.kind == .number {
                    result.insert(node)
                } else if traversable.contains(node.kind) {
                    todo = todo.union(node.neighbourNodes)
                }
            }
        }
        return result
    }
    
    func nodeAtLocation(_ loc:CGPoint, radius:CGFloat = 8) -> Node?
    {
        return allNodes.filter{ $0.kind != .connect && distance($0.location, loc) <= radius }.min{ distance($0.location, loc) < distance($1.location, loc) }
    }
    
    init()
    {
        nodes = [:]
        allNodes = []
        determineNodes()
        determineBlocks()
    }
}
