;; title:  Accounting with Emma
;; author: Dan Jacka
;; desc:   small business simulator
;; script: fennel
;; input:  gamepad
;; saveid: accountingwithemma

(fn tt [...] (trace (table.concat [...] " ")))

(fn add-into [to from]
 (each [k v (pairs from)] (tset to k (+ v (or (. to k) 0))))
  to)

(macro collect* [iter-tbl key-value-expr ...]
 `(let [tbl# {}]
   (each ,iter-tbl
    (match ,key-value-expr
     (k# v#) (tset tbl# k# v#)))
   tbl#))

(macro icollect* [iter-tbl value-expr ...]
 `(let [tbl# []]
   (each ,iter-tbl
    (tset tbl# (+ (length tbl#) 1) ,value-expr))
   tbl#))

(local puzzles
 [{:postings {:system {:cash 60} :user {:profit 60}}
   :narr "Gulp! Here goes! I set up a little\ngallery on dad's stall... and I sold\nthree paintings for $20 each. Great\nstart!"
   :hints ["Hint: press RIGHT to select the empty\nvalue then use UP or DOWN to set the\namount."
           "Hint: the accounts must balance! Make\ntotal claims match total resources."
           "Hint: when you're done press LEFT to\nmove back to the ledger."]}
  {:postings {:system {:cash 90} :user {:profit 90}}
   :narr "Time to go it alone! I rented my own\nstall this time. $50 for the hire, but\nit looked great and got lots of\nattention - I sold seven $20 paintings!"
   :hints ["Hint: seven paintings sold at $20\neach... that's $140 in revenue."
           "Hint: profit equals revenue minus the\n$50 expense for the stall hire."
           "Hint: $140 revenue minus $50\nexpenses... that's $90 profit!"]}
  {:postings {:system {:profit 150} :user {:cash 150}}
   :narr "Another excellent day at the market.\nThe busiest so far: I sold 4 paintings,\nincluding two big ones at $40 each.\nMinus $50 again for the stall."
   :hints ["Hint: hold down the Z key at the same\ntime as you press UP or DOWN to\nchange the amount by $50 increments."
           "Hint: remember that when no value is\nselected (no orange box), you can\npress UP or DOWN to review already\ncompleted transactions in the ledger."]}
  {:postings {:system {:inventory 100} :user {:cash -100}}
   :narr "Before now I've been using paint that\nI already had. I'm going to treat new\nsupplies as an asset of my business.\nFirst up: a fresh stock of acrylics!"
   :hints ["Hint: supplies and the money that pays\nfor them are both assets."
           "Hint: there are no claims in this\ntransaction, only resources."
           "Hint: since claims are $0, resources\nmust total $0 too!"]}
  {:postings {:system {:profit -10 :cash 30} :user {:inventory -40}}
   :narr "My back-of-the-envelope calculations\ntell me that a $20 painting in acrylics\ncosts $10 worth of supplies to make.\nSold four but $50 rent ate my profit!"
   :hints ["Hint: those four lots of supplies are\nfour tenths of my inventory."]}
  {:postings {:system {} :user {:inventory 400 :payable 400}}
   :narr "If I want more sales on market day I\nneed a more eye-catching stall, which\nmeans more paintings! The store let me\ntake $400 worth of supplies on credit."
   :hints ["Hint: remember that total resources\nand total claims must match."]}
  {:postings {:system {:inventory -120 :cash 190} :user {:profit 70}}
   :narr "I had a painting frenzy this week. On\nmarket day my stall looked its best\never. I sold twelve paintings, oh yes!"
   :hints ["Hint: Twelve $20 paintings sold is $240\nrevenue."
           "Hint: minus the $50 stall rent expense\nfrom the $240 revenue."
           "Hint: account for the 12 x $10 cost of\ninventory too."]}
  {:postings {:system {} :user {:cash 1000 :equity 1000}}
   :narr "Things are going so well. Now that I've\nstarted I want this business to grow\nand grow! I've invested $1,000 of my\npersonal savings as capital."
   :hints ["Hint: remember, hold down the Z key to\nincrement by 50 each time you press\nUP!"]}
  {:postings {:system {:cash -200} :user {:payable -200}}
   :narr "I paid off half my outstanding bill at\nthe art store today."
   :hints ["Hint: bills to pay are represented by\nthe payable claims account."]}
  {:postings {:system {:cash -40} :user {:profit -40}}
   :narr "A customer brought back a big $40\npiece. They'd found a smudge after\ngetting the painting home. I gave them\na full refund as a goodwill gesture."
   :hints ["Hint: gah, mistakes impact my profit!"]}
  {:postings {:system {:receivable 200 :profit 265} :user {:cash 100 :inventory -35}}
   :narr "Exciting! A customer asked me to do\na really huge piece. I took $100\ndeposit; they'll pay me the remaining\n$200 when I deliver the final picture."
   :hints ["Hint: this transaction also includes\nthe cost of supplies to make the\npiece."
           "Hint: it's more than the usual $10\ncost for a regular painting."
           "Hint: this really big piece costs $35\nto make!"]}
  {:postings {:system {:loan 2000} :user {:property 2000}}
   :narr "Nuts! Dad and I spent $2,000 fixing up\nthe garden shed to store paintings.\nDad said he considers me the shed's\nowner now. I consider him owed $2,000!"
   :hints ["Hint: remember, hold down the Z key to\nincrement by 50 each time you press\nUP!"]}
  {:postings {:system {:cash 400 :profit 100} :user {:inventory -100 :receivable -200}}
   :narr "Ten paintings sold at the market, plus\nthe commisioning customer collected\nthe final piece and paid me in full."
   :hints ["Hint: awaited payments are\nrepresented by the receivable\nresources account."
           "Hint: after this transaction I'm not\nowed anything."]}
  {:postings {:system {:cash -15 :profit -15} :user {}}
   :narr "Dad lugged boxes all afternoon so I\npaid him $15 - my first employee! Time\nfor a break for all of us. Press DOWN\nto finish!"}])

(local accounts
 [{:id :cash       :pos {:text 77  :box 46}}
  {:id :receivable :pos {:text 109 :box 78}}
  {:id :inventory  :pos {:text 141 :box 110}}
  {:id :property   :pos {:text 141 :box 110}}
  {:id :loan       :pos {:text 182 :box 151}}
  {:id :payable    :pos {:text 182 :box 151}}
  {:id :equity     :pos {:text 239 :box 208}}
  {:id :profit     :pos {:text 239 :box 208}}])

(local ledger [])
(each [_ {:postings {: system : user}} (ipairs puzzles)]
 (table.insert ledger (-> {}
                       (add-into system)
                       (add-into user))))

(fn resources [t] (+ t.property t.inventory t.receivable t.cash))
(fn claims [t] (+ t.equity t.profit t.loan t.payable))

(fn totaler []
 (local cache [])
 (fn totals [i]
  (if (= 0 i)
   (collect* [_ {: id} (ipairs accounts)]
    (values id 0))
   (let [t (collect* [_ {: id} (ipairs accounts)]
            (values id (or (. ledger i id) 0)))
         t (-> t (add-into (totals (- i 1))))]
    (tset cache i (-> {:resources (resources t)
                       :claims (claims t) }
                   (add-into t)))
    t)))
 (fn [upto]
  (if (= upto 0) (totals 0)
   (let [all (length ledger)]
    (when (< (length cache) all)
     (totals all))
    (. cache (or upto all))))))

(set ledger.totals (totaler))

(local s {})
(local modes {})

(var hinter nil)
(fn issue-hints []
 (let [hints (or s.puzzle.hints [])]
  (for [_ 1 500] (coroutine.yield))
  (each [i hint (ipairs hints)]
   (set s.puzzle.active-hint hint)
   (for [_ 1 500] (coroutine.yield)))
  (set s.puzzle.active-hint nil)
  (for [_ 1 500] (coroutine.yield))))

(fn modes.start-puzzle [n]
 (set s.puzzle (. puzzles n))
 (set s.puzzle.id n)
 (set s.cursor n)
 (set s.spinners
  (icollect* [_ {: id : pos } (ipairs accounts)]
   (let [target (. s.puzzle.postings.user id)]
    (when target {: id : pos : target :value nil}))))
 (set s.spindex 0)
 (set hinter (coroutine.create issue-hints))
 (set s.emma {}))

(fn scroll-ledger [dir]
 (set s.cursor (-> (+ dir s.cursor)
                (math.max 1)
                (math.min s.puzzle.id))))

(fn select-spinner [dir]
 (set s.spindex (-> (+ dir s.spindex)
                 (math.max 0)
                 (math.min (length s.spinners)))))

(fn spin-spinner [dir]
 (when (> s.spindex 0)
  (let [dir (if (btn 4) (* dir 50) dir)
        spinner (. s.spinners s.spindex)
        val (if (and (btn 6) (btn 7))
             spinner.target ;; cheat
             (+ (or spinner.value 0) dir))]
   (set spinner.value val))))

(fn puzzle-balances []
 (-> {}
  (add-into (ledger.totals (- s.cursor 1)))
  (add-into s.puzzle.postings.system)
  (add-into (collect* [_ {: id : value} (ipairs s.spinners)]
             (values id value)))))

(fn format-amount [amt]
 (if
  (not amt) ""
  (= 0 amt) ""
  (string.format "%+d" amt)))

(fn dotted-line [x0 y0 x1 y1 color]
 (for [x x0 x1 2]
  (for [y y0 y1 2]
   (pix x y color))))

(fn text-color []
 (if (= modes.win _G.TIC) 14 15))

(local tic80-print print)

(fn right-print [...]
 "Print a string from the right"
 (let [[text x y & rest] [...]
       width (tic80-print text 0 -6 (table.unpack rest))]
  (tic80-print text (- x width) y (table.unpack rest))))

(fn print [text x y options]
 (let [{: color : small? : right?} (or options {})
       f (if right? right-print tic80-print)]
  (f text x y (or color (text-color)) false 1 small?)))

(fn dialog [s]
 (var color (if (= "Hint" (s:sub 1 4)) 3 15))
 (var i 1)
 (each [line (string.gmatch s "([^\n]*)")]
  (print line 2 (+ 98 (* 8 i)) {: color})
  (set i (+ 1 i))))

(fn draw-transaction [n]
 (dialog (. puzzles n :narr))
 (each [_ {: id : pos} (ipairs accounts)]
  (when pos
   (let [amt (. ledger n id)]
    (print (format-amount amt) pos.text 35 {:right? 1})))))

(fn draw-active-puzzle []
 (dialog (or s.puzzle.active-hint s.puzzle.narr))
 (each [_ {: id : pos} (ipairs accounts)]
  (when pos
   (let [amt (. s.puzzle.postings.system id)]
    (print (format-amount amt) pos.text 35 {:right? 1}))))
 (each [i {: pos : target : value} (ipairs s.spinners)]
  (when (= i s.spindex)
   (rectb pos.box 34 31 7 5))
  (let [value (and value (format-amount value))
        text (or value "????")]
   (print text pos.text 35 {:right? 1 :color 3}))))

(fn iter-emma-portrait []
 (local traits
  {:blink {:flag true :timer 0 :wait #(math.random 200 600) :active (hashfn 10)}
   :purse {:flag true :timer 0 :wait #(math.random 400 600) :active #(math.random 100 1000)}})
 (fn []
  (each [t {: flag : timer : wait : active} (pairs traits)]
   (match [flag timer]
    [false 0] (do (tset (. traits t) :flag true)  (tset (. traits t) :timer (active)))
    [true 0]  (do (tset (. traits t) :flag false) (tset (. traits t) :timer (wait)))
    [_ _] (tset (. traits t) :timer (- timer 1))))
  { :blink? traits.blink.flag :purse? traits.purse.flag }))
(local update-emma (iter-emma-portrait))

(fn iter-sparks [key firework]
 (var i 1)
 (fn []
  (let [sparks []]
   (each [_ trail (ipairs firework)]
    (let [spark (. trail i)]
     (when spark
      (table.insert sparks spark))))
   (set i (+ i 1))
   (if (not (= (length sparks) 0))
    sparks
    (tset s.fireworks key nil)))))

(fn spark-trail [x y options]
 (local trail [])
 (let [options (or options {})
       theta (or options.theta 1)
       v (or options.v 40)
       col (or options.col 7)]
  (var (sx sy) (values x y))
  (while (and (> sx 0) (< sx 239) (< sy 135) (> sy -10))
   (let [t (+ 1 (length trail))
         dx (math.floor (* v (math.cos theta) t))
         dy (math.floor (- (* v (math.sin theta) t) (* 0.5 9.8 t t)))]
    (set sx (+ sx dx))
    (set sy (- sy dy))
    (table.insert trail { :x sx :y sy : col }))))
 (let [seq []
       dur (or options.dur 20)]
  (each [_ spark (ipairs trail)]
   (for [i 1 dur]
    (table.insert seq spark)))
  seq))

(fn light-firework [x y options]
 (let [key (.. x y)
       options (or options {})
       padding (or options.padding 10)
       n (or options.n 25)
       v (or options.v 20)
       spread (or options.spread :random)
       trails []]
 (for [i 1 n]
  (let [angle (match spread
               :even (* (- i 1) (/ 180 (- n 1)))
               _ (math.random 10 170))]
   (table.insert trails
    (spark-trail
     (+ x (math.random padding)) y
     {:dur 20
      :col (math.random 5 7)
      : v
      :theta (/ (* math.pi angle) 180)
      }))))
  (tset s.fireworks key (iter-sparks key trails))))

(fn draw-spark [x y color]
 (if (= modes.win _G.TIC)
  (circ x y 1 color)
  (pix x y color)))

(fn draw-fireworks []
 (each [_ firework (pairs s.fireworks)]
  (let [sparks (firework)]
   (when sparks
    (each [_ {: x : y : col} (ipairs sparks)]
     (draw-spark x y col))))))

(fn transition-to-puzzle [id]
 (set s.timer (if s.timer (+ 1 s.timer) 0))
 (when (= 0 s.timer)
  (each [_ {: id : pos} (ipairs accounts)]
   (when (and pos (. s.puzzle.postings.user id))
    (sfx 0 28 30 0)
    (light-firework (+ 10 pos.box) 34 {:n 10 :spread :even}))))
 (when (= 60 s.timer)
  (set s.timer nil)
  (modes.start-puzzle (+ 1 s.puzzle.id))))

(fn in-transition? [] s.timer)

(fn game-update []
 (set s.emma (update-emma))
 (when (= s.puzzle.id s.cursor)
  (when (= (coroutine.status hinter) "dead")
   (set hinter (coroutine.create issue-hints)))
  (coroutine.resume hinter)
  (when (= 0 s.spindex)
   (var solved true)
   (each [_ {: target : value} (ipairs s.spinners)]
    (when (~= target value)
     (set solved false)))
   (when solved
    (if (= (length puzzles) s.puzzle.id)
     (when (btnp 1) (global TIC modes.win))
     (transition-to-puzzle (+ 1 s.puzzle.id)))))))

(fn draw-game []
 (cls 1)

 ;; draw grid
 (line 25 0 25 103 14)
 (line 26 42 239 42 14)
 (line 26 44 239 44 14)
 (line 0 103 239 103 14)
 (dotted-line 26 7 239 7 14)
 (dotted-line 26 53 239 53 14)
 (dotted-line 44 17 44 41 14)
 (dotted-line 142 9 142 41 14)
 (dotted-line 133 55 133 102 14)

 ;; draw ledger
 (print "Ledger" 0 0 {:small? 1})
 (let [dy 3]
  (each [i _ (ipairs puzzles)]
   (let [y (+ 9 (* dy (- i 1)) i)
         colour (if (<= i s.puzzle.id) (text-color) 12)]
    (line 10 y 20 y colour))))

 ;; draw ledger pointer
 (let [dy 4
       y (+ (* dy (- s.cursor 1)) 8)]
  (tri 0 y
       5 (+ y 2)
       0 (+ y 4)
       4))

 ;; draw transaction details section
 (print " #" 30 18)
 (print "Transaction details" 97 0 {:small? 1})
 (print "Resources ($)" 58 10)
 (print "Claims ($)" 171 10)
 (print "Cash" 60 18 {:small? 1})
 (print "Receiv" 85 18 {:small? 1})
 (print "-ables" 85 25 {:small? 1})
 (print "Other" 118 19 {:small? 1})
 (print "assets" 118 25 {:small? 1})
 (print "Outsiders:" 146 18 {:small? 1})
 (print "liabilities" 146 25 {:small? 1})
 (print "Owner: capital" 191 18 {:small? 1})
 (print "and profit" 191 25 {:small? 1})
 (print s.cursor 40 35 {:right? 1})

 ;; draw balance sheet
 (print "Balance sheet" 108 46 {:small? 1})
 (print "Resources ($)" 45 56)
 (print "Property" 30 64)
 (print "Inventory" 30 72)
 (print "Receivable" 30 80)
 (print "Cash" 30 88)
 (print "TOTAL" 30 96)
 (print "Claims ($)" 162 56)
 (print "Equity" 140 64)
 (print "Profit" 140 72)
 (print "Loan" 140 80)
 (print "Payable" 140 88)
 (print "TOTAL" 140 96)
 (let [amounts (if (= s.puzzle.id s.cursor)
                (puzzle-balances)
                (ledger.totals s.cursor))
       {: property : inventory : receivable : cash
        : equity : profit : loan : payable } amounts
       resources (resources amounts)
       claims (claims amounts)
       color (if (= resources claims) (text-color) 5)]
  (print (format-amount property) 131 64 {:right? 1})
  (print (format-amount inventory) 131 72 {:right? 1})
  (print (format-amount receivable) 131 80 {:right? 1})
  (print (format-amount cash) 131 88 {:right? 1})
  (print (format-amount equity) 239 64 {:right? 1})
  (print (format-amount profit) 239 72 {:right? 1})
  (print (format-amount loan) 239 80 {:right? 1})
  (print (format-amount payable) 239 88 {:right? 1})
  (print (format-amount resources) 131 96 {: color :right? 1})
  (print (format-amount claims) 239 96 {: color :right? 1}))

 ;; draw Emma
 (spr 1 208 104 -1 1 0 0 4 4)
 (if
  s.emma.blink? (spr 5 216 112 -1 1 0 0 2 2)
  s.emma.purse? (spr 37 216 120 -1 1 0 0 1 2))
 (when (and s.emma.blink? s.emma.purse?)
  (spr 38 216 120))

 ;; draw the puzzle/transaction
 (if (= s.puzzle.id s.cursor)
  (draw-active-puzzle)
  (draw-transaction s.cursor)))

(fn game-input []
 (when (not (in-transition?))
  (if (= s.puzzle.id s.cursor)
   (if
    (and (= 0 s.spindex) (btnp 0)) (scroll-ledger -1)
    (btnp 0 30 6) (spin-spinner 1)
    (btnp 1 30 6) (spin-spinner -1)
    (btnp 2) (select-spinner -1)
    (btnp 3) (select-spinner 1))
   (if
    (btnp 0) (scroll-ledger -1)
    (btnp 1) (scroll-ledger 1)))))

(fn modes.play []
 (game-update)
 (draw-game)
 (draw-fireworks)
 (game-input))

(fn modes.prepare-game []
 ;; due to display limits, some account types are mutually exclusive in the same
 ;; posting
 (each [i entry (ipairs ledger)]
  (assert (not (and entry.equity entry.profit))
   (.. "Invalid game: ledger entry #" i " has both equity AND profit accounts!"))
  (assert (not (and entry.loan entry.payable))
   (.. "Invalid game: ledger entry #" i " has both loan AND payable accounts!"))
  (assert (not (and entry.property entry.inventory))
   (.. "Invalid game: ledger entry #" i " has both property AND inventory accounts!")))
 (assert (<= (length ledger) 23) "Invalid game: too many ledger entries!")
 (let [{: resources : claims} (ledger.totals)]
  (assert (= 0 (- resources claims)) "Invalid game: ledger totals do not balance"))
 (modes.start-puzzle 1))

(fn any-key-press []
 (var pressed? false)
 (for [i 0 7]
  (when (btnp i) (set pressed? true)))
 pressed?)

(fn start-game []
 (set s.timer nil)
 (set s.fireworks {})
 (modes.prepare-game)
 (music 0 0)
 (global TIC modes.play))

(fn modes.intro []
 (set s.timer (if s.timer (+ 1 s.timer) 0))
 (when (= 0 s.timer)
  (music 1 0 0 false))
 (cls 13)
 (when (< 12 s.timer)
  (spr 80 0 24 0 1 0 0 10 5)) ;; "Acc.."
 (when (< 24 s.timer)
  (spr 90 80 24 0 1 0 0 2 5) ;; "..o [first half].."
  (spr 92 96 24 0 1 0 0 4 4) ;; "..ou.."
  (spr 7 128 16 0 1 0 0 6 5)) ;; "..nt.."
 (when (< 48 s.timer)
  (spr 13 176 16 0 1 0 0 3 5) ;; "..in.."
  (spr 263 200 16 0 1 0 0 5 4) ;; "..ng"
  (spr 329 216 48 0 1 0 0 3 1)) ;; "g [tail]"
 (when (< 72 s.timer)
  (spr 160 0 64 0 1 0 0 10 6)) ;; "with"
 (when (< 120 s.timer)
  (spr 154 80 56 0 1 0 0 6 7) ;; "Em.."
  (spr 448 128 72 0 1 0 0 4 4))
 (when (< 132 s.timer)
  (spr 452 160 72 0 1 0 0 9 4) ;; ..ma"
  (spr 328 192 64 0) ; m [top]
  (spr 442 208 64 0 1 0 0 3 1)) ;; a [top]
 (when (< 240 s.timer) (start-game))
 (when (any-key-press) (start-game)))

(fn decay-over-time [start rate]
 (math.ceil (* start (^ (math.exp 1) (* rate s.timer)))))

(fn modes.win []
 (set s.timer (if s.timer (+ 1 s.timer) 0))
 (when (= 0 s.timer)
  (music))

 (match s.timer
  50 (light-firework 77 34 {:n 10})
  51 (sfx 5 16 50 0)
  100 (light-firework 155 74 {:n 10})
  101 (sfx 5 14 50 1)
  250 (light-firework 90 100 {:padding 60 :v 24 :n 100})
  251 (sfx 5 12 70 0)
  271 (sfx 5 16 70 1))

 (set s.emma (update-emma))
 (draw-game)

 ;; left landscape
 (let [ofs (decay-over-time -120 -0.03)]
  (rect 10 (+ 5 ofs) 66 50 3)
  (tri 10 (+ 5 ofs) 75 (+ 5 ofs) 43 (+ 38 ofs) 2)
  (tri 10 (+ 5 ofs) 10 (+ 54 ofs) 35 (+ 30 ofs) 2)
  (spr 256 15 (+ 10 ofs) -1 1 0 0 7 5))
 ;; right portrait
 (let [ofs (decay-over-time -100 -0.02)]
  (rect 175 (+ 15 ofs) 50 66 3)
  (tri 175 (+ 15 ofs) 224 (+ 15 ofs) 200 (+ 40 ofs) 2)
  (tri 175 (+ 15 ofs) 175 (+ 80 ofs) 208 (+ 48 ofs) 2)
  (spr 336 180 (+ 20 ofs) -1 1 0 0 5 7))
 ;; middle portrait
 (let [ofs (decay-over-time -200 -0.05)]
  (rect 90 (+ 25 ofs) 60 76 2)
  (rect 92 (+ 27 ofs) 56 72 0)
  (rect 93 (+ 28 ofs) 54 70 2)
  (rect 94 (+ 29 ofs) 52 68 0)
  (rect 95 (+ 30 ofs) 50 66 2)
  (spr 341 100 (+ 35 ofs) -1 1 0 0 5 7))

 ;; black block
 (rect 0 104 207 135 1)
 (dialog "Thank you for helping me turn my\npassion for painting into a successful\nbusiness! Next up: my art hanging in\nrooms across the entire world!")

 (draw-fireworks)

 (when (and (> s.timer 300) (any-key-press))
  (set s.timer nil)
  (global TIC modes.intro)))

(global TIC modes.intro)

;; <TILES>
;; 001:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0aaaaaa00aaaaa00caaaaa0cc
;; 002:aaaaaaaaaaaaaaaaaa000000000ccccf0ccccccccccccccccc000000c0000000
;; 003:aaaaaaaaaaaaaaaa0000aaaaff000aaaccff00aaccccc00a000ccc0000000cc0
;; 004:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0aaaaaaa
;; 005:0000000000000000002200220233333300333333111133333333333303301333
;; 006:000000c0000000c0220000003320000033200000111200003311120013302200
;; 011:000000000000ffff000ffebf000fbbbf000fbbbf000fbbbf000fbbbf000fbbbf
;; 012:0000000000000000f0000000f0000000f0000000f0000000f0000000f0000000
;; 013:0000000f000000ff00000ffb00000ffb00000ffb000000fb000000ff0000000f
;; 014:fff00000feff0000bccff000cbcff000bcbff000ccbf0000fff00000ff000000
;; 015:000000000000000000000000000000000000000000000000000fffff000ffccf
;; 017:aaaaa0ccaaaaa0c0aaaaa000aaaaa000aaaaa000aaaa0000aaaa0002aaaa0002
;; 018:0000000000000000002200220233333300333333111133333333333300001333
;; 019:000000c0000000c0220000003320000033200000111200003311120010002200
;; 020:0aaaaaaa0aaaaaaa0aaaaaaa00aaaaaa00aaaaaa000aaaaa0000aaaa0000aaaa
;; 021:3003333333333333333333333333233333332333333332233333333303344ee4
;; 022:3001d20033333200333332003333100033333000333330003333300043330000
;; 023:00000000000000000000000000000000000000ff00000ffb00000fbb00000fbb
;; 024:00000000000000000000000000000000ff0000ffbff00ffebbffffbbbbffbbbb
;; 025:0000000000000000000000000ffff000ffbbfff0bbbbbef0bbbbbbffbbbbbbbf
;; 026:00000000000000000000000000000fff0000ffbb0000fbbb0000febb0000fffe
;; 027:00ffbbbf00ffbbbfffffbbbbffebbbbbbbbbbbbbbbbbbbbbbbbbbbbffffebbbf
;; 028:f0fff000ffffff00bbbbbff0bbbbbff0bbbbbff0beffff00ffff000000000000
;; 029:000000ff00000ffc00000ffb00000ffb00000ffb00000feb00000feb00000fbb
;; 030:fff00000bbf00000bbff0000bbff0000bbff0000bbf00000bbf00000bbf00000
;; 031:000fcccc000fcccc000fcccc000fcccc00ffcccc00ffcccc00ffcccc00ffcccc
;; 033:aaa00002aaa00002aa000002aa000003aaa00003aaa00000aaa00000aaa00000
;; 034:ef013333389e3333333333333333233333332333333332233333333303344ee4
;; 035:e901d20038933200333332003333100033333000333330003333300043330000
;; 036:0000aaaa0000aaaa00000aaa00000aaa0000aaaa0000aaaa00000aaa00000aaa
;; 037:ef013333389e3333333333333333233333332333333332233333333303344444
;; 038:3003333333333333333333333333233333332333333332233333333303344444
;; 039:00000fbb00000fbb00000fbb00000fbb00000fbb00000fbb00000fbb00000fbb
;; 040:bbfbbbbbbbbbbbbbbbbbbbefbbbbbfffbbbbff00bbbff000bbff0000bbf00000
;; 041:bbbbbbbffffbbbbff0febbbf00ffbbbf00febbbe00febbbf00febbbf00fbbbbf
;; 042:f0000ffff0000000f0000000f0000000f0000000f0000000f0000000f0000000
;; 043:fffbbbbf00fbbbbf00fbbbbf00fbbbbf00fbbbbf00fbbbbf00fbbbbf00fbbbbf
;; 045:00000fbb00000fbb00000fbb00000fbb00000fbb00000fbb0000ffbb0000ffbb
;; 046:bbf00000bbf00000bbf00000bbf00000bbf00000bbf00000bbf00000bbf00000
;; 047:00ffcccc00ffcccf00fecccf00fecccf00fccccf00fccccf00fccccf00fccccf
;; 049:aa000000aaa00000aaa00000aa000000a0000000a0000000a0000003a0000033
;; 050:003344440003333300003333000003330000333300333333cc3333333cc33333
;; 051:3330000033000000310000003333c0003333c3333333c333333ccc33333ccc33
;; 052:00000aaa000000aa0000000a0000000a0000000a300000aa330000aa330000aa
;; 053:003334430003333300003333000003330000333300333333cc3333333cc33333
;; 055:0000ffbb0000ffbb0000ffbb0000febb0000fbbb0000fbbb0000fbbb0000ffbb
;; 056:bff00000bff00000bff00000bff00000bff00000bf000000bf000000ff000000
;; 057:00fbbbbf00fbbbbf00fbbbbf00fbbbbf0ffbbbff0ffbbbff00ffeff0000fff00
;; 058:f0000000f0000000000000000000000000000000000000000000000000000000
;; 059:0ffbbbbf0ffbbbef0ffbbbff0ffbbbff0ffbbbf000fffff00000000000000000
;; 061:0000ffbb0000ffbb00000fbb00000fff00000000000000000000000000000000
;; 062:bef00000bff00000bff00000ff00000000000000000000000000000000000000
;; 063:00fccccf00ffccff000ffff00000000000000000000000000000000000000000
;; 071:00000fff00000000000000000000000000000000000000000000000000000000
;; 072:ff00000000000000000000000000000000000000000000000000000000000000
;; 081:000000000000000000000000000000000000000f000000ff00000ffc0000ffcc
;; 082:00000ff0000fffff00ffcccffffcccccfcccccccccccccccccccccccccccffcc
;; 083:0000000000000000f0000000ff000000cf000000cff00000ccf00000ccf00000
;; 093:000000000000000000000000000000000000000000000000000000ff00000fff
;; 094:000000000000000000000000000000000000000000000000f0000000ff000000
;; 095:000000000000000000000000000000000000000000fffff00ffebff00ffbbbf0
;; 096:0000000000000000000000000000000000000000000000000000000f0000000f
;; 097:000ffccc000feccc00fecccc0ffcccccffcccccfffccccfffccccdf0eccccff0
;; 098:cccfffccccff0ffceff00ffcff0000fcf00000ff000000ff0000000f0000000f
;; 099:ccef0000cccf0000cccff000cccff000ccccf000ccccf000ccccff00ecccff00
;; 101:0000000000000000000000000000000000000000000fffff0fffffccffeccccc
;; 102:0000000000000000000000000000000000000000ffff0000ccefff00cccccf00
;; 103:00000000000000000000000000000000000000000000000f000000ff00000ffb
;; 104:000000000000000000000fff00ffffff0fffbbbbffbbbbbbbbbbbbbbbbbbbbef
;; 105:0000000000000000fff00000ffffff00bbbbfff0bbbbbff0bbbbbff0ffebeff0
;; 106:00000000000000000000000f000000ff00000ffb0000ffbb0000febb000ffbbb
;; 107:0000ffff0fffffffffbbbbbbbbbbbbbbbbbbbbbbbbbeffffbbffffffbff00000
;; 108:ff000000ffff0000bbbff000bbbbff00bbbbef00bbbbbff0febbbef0ffbbbbf0
;; 109:0000ffbb0000ffbb0000fbbb000ffbbb000ffbbb000febbb000fbbbb000fbbbb
;; 110:bff00000bff00000bf000000bf000000bf000000ef000000ff000000f0000000
;; 111:0fbbbbf00fbbbbf00fbbbbf00fbbbbf0ffbbbff0ffbbbff0ffbbbff0febbbff0
;; 112:000000ff000000fc00000ffc00000ffc00000fcc0000ffcc0000fccc000ffccc
;; 113:ccccef00ccccf000cccfffffcccfffffccfccccccccccccccccccccccccccccf
;; 114:000000ff00ffffffffffecccccccccccccccccccccccccccccceffffffffff00
;; 115:fccccf00fccccf00cccccf00cccccff0cccccff0cccccff0ffcccef0ffccccf0
;; 116:000000ff00000ffc00000fec0000ffcc000ffccc000ffccc000fcccc00ffcccc
;; 117:ccccccccccccccccccccefffcccfff00ccff0000cff00000ff000000f0000000
;; 118:cccccf00cccccf00ffffff00000f000000000000000000000000000000000000
;; 119:0000ffbb0000ffbb0000fbbb000ffbbb000fbbbb000fbbbb000fbbbf00ffbbbf
;; 120:bbbeffffbbeff000bbf00000bff00000ff000000f0000000f0000000f0000000
;; 121:fffff00000000000000000000000000000000000000000000ffff000ffeff000
;; 122:000ffbbb000fbbbb000fbbbe000fbbbf000fbbbe000fbbbb000ffbbb000ffbbb
;; 123:ff000000f0000000f0000000f0000000f0000000f0000000fff000ffbffffffb
;; 124:0ffbbbf00ffbbbf00ffbbbf00febbbf0ffbbbbf0ffbbbff0ebbbbf00bbbbff00
;; 125:000fbbbb000fbbbb000fbbbb000fbbbb000fbbbb000ffbbb0000fbbb0000ffbb
;; 126:f0000000f000000ff00000fff0000ffbff0fffbbbfffbbbbbbbbbbbbbbbbbbbe
;; 127:fbbbbf00fbbbbf00bbbbbf00bbbbbf00bbbbbff0bbbbbff0bfbbbef0ffbbbbf0
;; 128:000feccc000fcccc00ffcccc00feccce00fccccf0ffccccf0ffccccf0fcccccf
;; 129:cceffffffffff000f0000000f0000000f0000000000000000000000000000000
;; 130:ff00000000000000000000000000000000000000000000000000000000000000
;; 131:ffccccf0ffccccf00fccccf00fccccf00fccccf00fccccf00fccccf00fccccf0
;; 132:00ffccce00ffcccf00ffcccf00ffcccf00ffcccc000fcccc000ffccc0000ffcc
;; 133:f0000000000000000000000ff0000fffffffffcccefccccccccccccccccccccc
;; 134:00000000fffff000feccf000ccccf000ccccf000cccff000ccff0000fff00000
;; 135:000fbbbf000fbbbb000fbbbb000ffbbb0000febb0000fffb00000fff0000000f
;; 136:f00000ffff00fffebffffebbbbbbbbbbbbbbbbbbbbbbbbbffebbffffffffff00
;; 137:fbbbff00bbbbff00bbbbff00bbbff000bfff0000ff000000f000000000000000
;; 138:0000febb0000ffbb00000ffb000000ff00000000000000000000000000000000
;; 139:bbbbbbbbbbbbbbbbbbbbbbbbfbbbbbefffffffff000000000000000000000000
;; 140:bbbbf000bbbff000bfff0000ff00000000000000000000000000000000000000
;; 141:00000ffb000000ff0000000f0000000000000000000000000000000000000000
;; 142:bbbbbbffebbffff0fffff0000000000000000000000000000000000000000000
;; 143:ffbbbff00fffff00000ff0000000000000000000000000000000000000000000
;; 144:0fccccefffccccffffccccf0ffccccf0ffcccff00ffcfff00fffff0000000000
;; 147:0fccccff0fccccff0ffcccf00ffccff000ffff00000000000000000000000000
;; 148:00000ffc000000ff000000000000000000000000000000000000000000000000
;; 149:ccccccfffffffff0000000000000000000000000000000000000000000000000
;; 150:f000000000000000000000000000000000000000000000000000000000000000
;; 156:0000000000000000000000000000000000000000000000000000000000000fff
;; 157:00000000000000000000000000000000000000000000000000000fffffffffff
;; 158:000000000000000000000000000000000000000000000000ff000000ffff0000
;; 167:000000000000000000000000000000000000000f000000fb000000fb000000fb
;; 168:00000000000000000000000000000000ff000000bf000000bf000000bf000000
;; 171:00000000000000ff0000ffff00ffffbb0fffbbbb0ffbbbbbffbbbbbbffbbbbbb
;; 172:00ffffffffffebbbfebbbbbbbbbbbbbbbbbbbbbbbbbbbbeebbbeffffffffff00
;; 173:feebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbeffffffffffff0000000000000
;; 174:bbff0000bbef0000bbef0000bbff0000ffff0000ff0000000000000000000000
;; 180:000000000000000000000000000000000000000000000000000000000fff0000
;; 181:00000000000000000ffff000fbccf000fecbf0000fff00000fff0000fccf000f
;; 182:0000fff0000fbbf0000fbbf0000fbbf0000fbbff00ffbbbbfbbbbbbbbbbbbbef
;; 183:000000fb000000fb000000fb000000fbff0000fbbbf000fbbbf000ebff0000eb
;; 184:bf000000bf000000bf000000bf00ffffbfffbbbbbffbbbbbbebbbfbbbbbeffbb
;; 185:00000000000000000000000000000000f0000000f0000000e0000000bf000000
;; 186:000000000000000f0000000f0000000f0000000f000000ff000000ff000000ff
;; 187:febbbbbffbbbbbfffbbbbbfffbbbbef0ebbbbff0bbbbbff0bbbbbfffbbbbbfff
;; 188:fff00000000000000000000000000000000000ff00fffffffffffebbfebbbbbb
;; 189:00000000000000000000000000000000fff00000ffff0000bbbff000bbbff000
;; 191:00000000000000000000000000000000000000000000000f00000fff00000ffe
;; 194:0ff00000fccf0000fccf0000fcccf0000eccf00f0fccf00e0fcce0fc00fccfcc
;; 195:00f000000feff000fcccf000fcccef0fcccccffeccfccffccefccecccf0ecccc
;; 196:0fccf000fccef000eccf0000cce00000ccf00000cf000000cf000000f0000000
;; 197:fccf0000fccf0000fccf0000fccf0000fccf0000fccf0000fccf0000fccf0000
;; 198:feffbbf0000fbbf0000fbbf0000fbb00000fbe00000fbe00000fbe00000ebf00
;; 199:000000eb000000bb00000fbb00000fbb00000fbb00000fbb00000fbb000000ff
;; 200:bbff00ebbff000ebe0000fbbf0000fbbf0000fbbf0000fbbf0000feef0000000
;; 201:bf000000bf000000bf000000bf000000e0000000f0000000f000000000000000
;; 202:000000ff000000fe000000fb000000fb00000ffb00000ffb00000ffb00000ffb
;; 203:bbbbbebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbefffbbbeffffbbbff000
;; 204:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbefbbeeffffffffff00ff00000000000000
;; 205:bbbff000bbeff000bfff0000fff00000f0000000000000000000000000000000
;; 207:0000ffbb0000ffbb0000ffbb0000ffbb0000ffbb0000ffbb0000ffbb0000ffbb
;; 210:00fccccc000ecccf000fcce00000fff000000000000000000000000000000000
;; 211:f00fccce000fcccf0000fcf000000f0000000000000000000000000000000000
;; 212:f000000000000000000000000000000000000000000000000000000000000000
;; 213:fccf0000fff00000000000000000000000000000000000000000000000000000
;; 214:000fff0000000000000000000000000000000000000000000000000000000000
;; 218:00000feb00000feb00000fbb00000fbb00000fbb00000fbb00000fbb00000fbb
;; 219:bbbff000bbbff000bbbff000bbbff000bbbff000bbbff000bbbf0000bbbff000
;; 221:0000000000000000000000000000000000000000000000ff000ffffffffffebb
;; 222:000000000000000000000000000000000ff00000fffff000bbbeff00bbbbff00
;; 223:0000febb0000febb0000febb0000fbbb000ffbbb000ffbbb000ffbbb000ffbbb
;; 234:00000fbb00000fbb00000fbb00000fbb00000feb00000ffb00000ffe000000ff
;; 235:bbbff000bbbff000bbbfffffbbbbffffbbbbbbbbbbbbbbbbbbbbbbbbebbbbbbb
;; 236:00000fff00fffffeffffebbbebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbebbbbffff
;; 237:ffebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbeffbbeffff0fffff000ff000000
;; 238:bbbbff00bbbeff00bbeff000efff0000fff00000000000000000000000000000
;; 239:000ffbbb000ffbbb000ffbbb000ffbbb000ffebb0000ffff00000fff00000000
;; 250:0000000f00000000000000000000000000000000000000000000000000000000
;; 251:fffeeeeeffffffff000000000000000000000000000000000000000000000000
;; 252:fffffff0ffff0000000000000000000000000000000000000000000000000000
;; </TILES>

;; <SPRITES>
;; 000:ddddddddddddddddddddddddddddddddddddddddddddddddddddccccdccccccc
;; 001:dddddddddddddddddddddddddddddddddddddddccccccccccccccccccccccccc
;; 002:dddddddddddddddddddddddddddccccccccccccccccccccccccccccccccccccc
;; 003:dddddddddddddcccccccccccccccccccccccccccccccccccccccccccccccccbb
;; 004:dcccccccccccccccccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbb
;; 005:ccccccccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbb
;; 006:ccccddddccccccddccccccccccccccccccccccccbbbcccccbbbbbbbbbbbbbbbb
;; 007:0000000000000000000000000000000000000000000000ff0000fffcf0fffccc
;; 008:0000000000000000000000000000000000000000ffff0000cccff000ccccf000
;; 009:000000000000000000000000000000000000000000000000000000ff00000ffe
;; 010:000000000000000000000000000fffff0fffffccfffcccccfccccccccccccccc
;; 011:000000000000000000fffff0ffffcff0effcccffcffcccffcffcccffefecccff
;; 016:ccccccccccccccccccccccccccccccccccccccbbcbbbbbbbbbbbbbbbbbbbbbbb
;; 017:cccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
;; 018:ccccccccccccccbbcbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb777b7777777
;; 019:ccbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7bbbbb777b77777777777999779899899
;; 020:bbbbbbbbbbbbbbbbbbbbbbbb7777777b77777777777766667799966689989989
;; 021:bbbbbbbbbbbbbbbbbbbbbbbbbbb7777777777766666666666666666698999666
;; 022:bbbbbbbbbbbbbbbbbb7777bb7777777766666666666666666666666666666666
;; 023:fffcccccffccccccfccccccfccccccffccccfff0cccff000ccff0000cff00000
;; 024:ccccff00cccccf00cccccf00fccccf00fccccff0fecccff0fecccff0fccccff0
;; 025:00000fec0000ffcc0000fccc000ffccc000fcccc000fcccc000fccce000fcccf
;; 026:ccccffffcccfff00ccff0000cff00000ff000000f0000000f000000ff00000ff
;; 027:ffccccff0fccccff0fccccf00fccccf00fccccf0ffccccf0fcccccf0ccccccf0
;; 032:bbbbbbbbbb77777bb77777777777776677766666666666666666666666666666
;; 033:bbbb777777777777777766667766666666666998666698996699999966989999
;; 034:7777799877799899699899999899999999999999999999999999999999999999
;; 035:9999999999999999999999999999999999999999999999999999999999991111
;; 036:9999999999999999999999999999999999999999999999999999999911119999
;; 037:9999899999999989999999999999999999999999999999999999999999999999
;; 038:9966666699999666899996669999996698999996999999969999999699999996
;; 039:ff000000f000000000000000000000000000000f0000000f0000000f0000000f
;; 040:fccccff0fccccf00fccccf00fccccf00fccccf00fcccef00fcccff00fcccf000
;; 041:000fcccc000fcccc000feccc0000fccc0000ffcc00000ffe000000ff00000000
;; 042:f000fffcfffffccccccccccccccccccccccccccfcccccffffffffff00ff00000
;; 043:ccccccf0ccccccf0cccccef0cfcccff0ffcccff0ffcccff0ffcccff0fecccff0
;; 048:6666666666666666666666666666666966666699666666896666699966669899
;; 049:6699999969899999999999998999999199999113999113369913366611366666
;; 050:9999999999199999991199991133199933666111666666636666666666666666
;; 051:9911333391133666999111669999991699999999111199913333111366663336
;; 052:3333399966666999666666996666669913666669136666663666666666666666
;; 053:9999199919919999111999991339991993399189666991196669999966669999
;; 054:9999199699999136999991369919913691899136911913669999136699913666
;; 056:fffff0000fff0000000000000000000000000000000000000000000000000000
;; 057:0000000000000000000000000000000000000000000fffff000fccce000fcccc
;; 058:00000000000000000000000000000000000000000000000fff000fffcffffffc
;; 059:fccccff0fccccf00fccccf00fccccf00fccccf00fccccf00ccccff00ccccf000
;; 064:6666999166699913669911366691336669916666666666666666666666666666
;; 065:3366666666666666666666666666666666666666666666666666666666666666
;; 066:6666666666666666666666666666666666666666666666666666666666666666
;; 067:6666666666666666666666666666666666666666666666666666666666666666
;; 068:6666666666666666666666666666666666666666666666666666666666666666
;; 069:6666999966669999666999996669999966669999666699996666991166666666
;; 070:9913666699136666913666669136666691366666136666663666666666666666
;; 072:00000000000000000000000000000000000000000000000000000000ffffffff
;; 073:000fcccc000ffccc0000ffcc00000fff0000000f000000000000000000000000
;; 074:cccfcccccccccccccccccccccccccccfffffffff00ff00000000000000000000
;; 075:cccff000ccff0000cff00000ff00000000000000000000000000000000000000
;; 080:deeddddddeedddeedeedeedddeeedddedeedd7dddeeddddedeedd7dddeedddde
;; 081:eeddd7dedddeddded7ddd7dedddeddded7ddd7dedddeddded7ddd7dedddeddde
;; 082:dddddddddd7ddddddddddd7dddddddddddd7dddddddddddddddddddddd7ddd7d
;; 083:ed7dddeeedddeddded7ddd7dedddeddded7ddd7dedddeddded7ddd7dedddeddd
;; 084:dddddeedeedddeedddeedeededddeeeddd7ddeededdddeeddd7ddeededdddeed
;; 085:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
;; 086:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
;; 087:bbbbbbbbbbbbbbbbbbbbbbbbbbbb4b4bbbb44444bbb44444bbb44444bbb4b4b4
;; 088:bbbbbbbbbbbbbbbbbe3bbbbb4b3bbbbb4b3bbbbb4e3bbbbb4b3bbbbbbb3bbbbb
;; 089:b666666b66767666677777666677766666677766b666766bbb6666bbbbbbbbbb
;; 096:deedd7dddeeddddedeedd7dddeeddddedeedd7dddeeddddedeedd7dddeedddde
;; 097:d7ddd7dedddeddded7ddd7dddddeddddd7ddd7d5dddeddd5d7dddd5ddddddd5d
;; 098:ddddddddddddddddddddddddddddddddddd00dddd00000ddd00330dd0033330d
;; 099:ed7ddd7dedddeddded7ddd7dedddeddded7ddd7dedddeddded7dddd5edddddd5
;; 100:dd7ddeededdddeeddd7ddeededdddeeddd7ddeeddddddeeddd7ddeeddddddeed
;; 101:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
;; 102:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
;; 103:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb99bbbb99febbbbfedfbbbbfefebbbbfefe
;; 104:bb3bbbbbbb3bbbbbaa3aabbb99999aabfefef99adfdfdef9fefefedefefefefe
;; 105:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
;; 112:deedd7dddeeddddddeeddeeeddeeeddd7dddddddddddddddddd6dddddddd66de
;; 113:d7ddd3dddedd3dddeddd3ddddddd3ddd7ddd3dddddddd3dddddddd33ddd7dddd
;; 114:0333330dd033300d000300dd00f3f0ddd3f3f3dd3fffff3ddf4f4fd3dff4ffdd
;; 115:eddddd5deeedd5ddddddd3dddddd3dddddd3ddddd33ddd7d33dddddd3ddddddd
;; 116:dd7ddeeddddddeeddd7ddeededdddeeddeeedeedddddeeddddddddddddd6dddd
;; 117:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
;; 118:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
;; 119:bbbffeefbbbfefefbbbfefefbbbfe999bb999fefbbefedfdefefefefefefefef
;; 120:effefefeefefeffeefefefeb99efefebef99efebfdef99ebeffdef9befefedeb
;; 121:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
;; 128:dddddd6ddd7ddde6dddddeddddddedddd7ddedddddddedddddddeddddddded7d
;; 129:dddddd7d6dddddddd6ddddddddd7dd007d000044dd044444dd044444dd044444
;; 130:df4f4fdddff4ffdddff4ffdd00fff00040fff04440fbf04440bbb04440bbb044
;; 131:dddd7dde7ddddddddddddd660dddd6dd40000ddd44440ddd44440ddd44440d7d
;; 132:d66ddddd6ddddddddedd7ddddedddddddedddd7ddeddddddded7dddddedddddd
;; 133:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
;; 134:bbbbbbbbbbbbbbbbbbbbbbbebbbbbbbebbbbbbbebbbbbbb9bbbbbbbfbbbbbbef
;; 135:efefefefeefefefefefefefefefefefef99999999fefefefedfdfdfdefefefef
;; 136:efefefefffefefeffefeffebfefefefb9efefefbe9999efbfefef9fbefdfdebb
;; 137:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
;; 144:dd7deddddddde00edddde040dddde044d7dde044dddde044dddde044dddde044
;; 145:dd044444ee04000000004001444401114440111144001111440111f140011f1f
;; 146:0000000401111100111111111111111111111111111111111111111f1f1f1ff1
;; 147:44440dd00004000400400444110444401110000e11100dde11110ddeff1100de
;; 148:00dddddd40dddd7d40dddddd00dddddddedd7ddddedddddddedddddddeddddd7
;; 149:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
;; 150:bbbbbbefbbbbbefebbbbbefebbbbbefebbbbb999bbbbbefebbbbbfdfbbbbbefe
;; 151:efefefeffefefefefefefefefefefefe99999999fefefefedfdfdfdffefefefe
;; 152:efefefbbffefefbbfefeffbbfefefbbb9efefbbbf999fbbbdefe9bbbffdfbbbb
;; 153:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
;; 160:dddde044cccce044cccce044c7cce004ccccecb0cccecebbcceecbbbccccbbbb
;; 161:4011111140111111401111114011111100111111b0011111bb011111bb001111
;; 162:11f1111111111111111111111111111111111111111111111111111111111111
;; 163:111110de111110de111110be111110be111110be111100eb11110bbb11100bbb
;; 164:deddddddceccccccceccccccececcc7cbceecccceccccccceeccc7ccbbbccccc
;; 165:bbbbbbbbbbbbbbbbbbbbbcccbbbcccc3bccccc22cccc2222cc222222c2222222
;; 166:bbbcfefeccccefefccccefef3cccefef233d9999222efefe222effef222effef
;; 167:fefefefeefefefefefefefefefefefef9999999ffefefef9ffefffeeffefffef
;; 168:fefebbbbfefeccccefefccccefefccccefefcccc999cccccfeedccccffeddd22
;; 169:bbbbbbbbbbbbbbbbccccbbbbccccccbbccccccccc233cccc22223ccc2222233c
;; 176:c7ccbbbbcccbbb7bcccbbbbbccbbbbbbccbbbbbbcbbbbbb7cbbbbbbbbbbbbbbb
;; 177:bbb01111bbbb0111bbbb1001bbb11100bbbbccccbbbbccccbbbbccc7bbbbcccc
;; 178:111111111111111111111111011111000000000ccccccccccccccc7ccccccccc
;; 179:1110bbbb110bbbbb001bbbbb0111bbbbccbbb7bbccbbbbbbccbbbbbbcccbbbbb
;; 180:7bbbccccbbbbcc7cbbbbbcccb7bbbbccbbbbbbbcbbbbbbbcbbb7bbbbbbbbbbbb
;; 181:2222222222222222122222221222222211112888188888998889999989999999
;; 182:222effef22effeff22effeff22effeff99f99999999999999999999999999999
;; 183:ffefffeffefffefffefffefffefffeff99999999999999989999988899988888
;; 184:ffeddd22fefd2222fe222222fe2222229f888888888888888888888888888888
;; 185:2222222322222222222222222222222188821111888888818888888888888888
;; 186:000000000000000000000000000000000000000000000000000000ff0000fffe
;; 187:0000000000000000000000000000000000000000fffffffffffecccecccccccc
;; 188:0000000000000000000000000000000000ffff00ffffeff0ffecccffefccccff
;; 192:0000000000000000000000000000000000000000f000000ffff000ffbffffffe
;; 193:0000000000000000000000000000000000ffff00fffffff0febbbeffbbbbbbff
;; 194:0000000000000000000000000000000f00000fff000fffeb00fffbbb0fffbbbb
;; 195:000000000000000000000000fffff000feeefff0bbbbbff0bbbbbeffbbbbbbff
;; 196:00000000000000000000000f000000ff000000ff000000ff000000ff000000ff
;; 197:000000000fff0000fffff00ffccff0ffccccfffeccccffccccccfccccccccccc
;; 198:000fffff0ffffffffffccccefccccccccccccccccccccccccccccccccccffccc
;; 199:000000fff0000fffff00ffecff0ffccccfffcccccffccccccfccccccccccccce
;; 200:ffecceffcccccccfccccccceccccccccccccccccccecccccefffccccffffcccc
;; 201:f0000000f0000000f0000000ff000000ff000000ff00000fff00000fff00000f
;; 202:000fffcc00ffeccc0ffeccccfffcccccffccccccfccccceffcccceffeccccff0
;; 203:ccccccccccccccccccccceffccefffffffff000ff000000f0000000f0000000f
;; 204:efccccfffeccccfffeccccf0fccccef0fccccff0fccccff0fccccff0fccccff0
;; 208:bbffffbbbbfffbbbbbfebbbbbbebbbbbbbbbbbbbbbbbbbbfbbbbbbffbbbbbff0
;; 209:bbbbbbbfbbbbbbbfbbbbbbbebeebbbbbfffebbbbfffebbbb00ffbbbb00ffbbbb
;; 210:ffebbbbbffbbbbbbfbbbbbbfbbbbbbffbbbbbff0bbbbff00bbbeff00bbbff000
;; 211:bbbbbbffbbbbbbffffbbbbffffbbbbefffbbbbefffbbbbefffbbbbefffbbbbef
;; 212:000000ff000000fe000000fe000000fe000000fc00000ffc00000ffc00000ffc
;; 213:ccccccccccccccccccccccceccccccefccccceffcccccff0ccccff00cccef000
;; 214:cefffccceffffcccff00feccf000fecc0000fecc0000fccc0000fecc0000fccc
;; 215:cccccccfccccccffcccccff0ccccff00ccceff00cccff000ccef0000ccff0000
;; 216:f0ffcccc00ffcccc00ffcccc00ffcccc00ffcccc00fecccc00fecccc00fecccc
;; 217:ff0000ffff0000ffff0000ffff0000ffff0000ffff00000fff00000fff00000f
;; 218:ccccef00ccccff00ccccff00ccccff00ccccef00eccccff0fcccccfffeccccce
;; 219:0000000f0000000f0000000f0000000f00000fff000ffffcfffffeccffeccccc
;; 220:eccccff0eccccf00eccccf00ccccef00ccccef00ccccef00ccccef00ccccef00
;; 224:bbbbff00bbbff000bbfff000bbff0000bbf00000bef00000bef00000bff00000
;; 225:00ffbbbb00ffbbbb00ffbbbb00febbbb00febbbb00febbbb00fbbbbb00fbbbbb
;; 226:bbff0000bff00000bff00000ff000000ff000000ff000000f0000000f0000000
;; 227:ffbbbbffffbbbbffffbbbbfffebbbbfffebbbbfffebbbbfffebbbbfffebbbbff
;; 228:00000ffc00000ffc00000ffc00000ffc00000ffc00000ffc00000fec00000ffc
;; 229:cccff000cccff000cccff000cccff000cccff000cccff000cccff000cccff000
;; 230:000ffccc000ffccc000ffccc000ffccc000ffccc000ffccc000ffecc0000ffff
;; 231:ccff0000cef00000cef00000cef00000cff00000cff00000eff00000ff000000
;; 232:00fccccc00fccccc00fccccc00fcccce00fecccf00ffccef000fffff0000ff00
;; 233:ff000000ff000000f0000000f0000000f0000000f00000000000000000000000
;; 234:ffcccccc0ffccccc00ffeccc000fffec0000ffff000000ff0000000000000000
;; 235:cccccccccccccccccccccccfcccccffffffffff0ffff00000000000000000000
;; 236:cccccf00eccccff0feccff00ffffff000ffff000000000000000000000000000
;; 240:bff00000bff00000bff00000bff00000eff00000ff000000f000000000000000
;; 241:0ffbbbbe0ffbbbbf00febbbf00ffeeff000fffff000000000000000000000000
;; 242:f0000000f0000000f0000000f000000000000000000000000000000000000000
;; 243:ffbbbef0ffbbbff00ffffff000fff00000000000000000000000000000000000
;; 244:00000ffe000000ff0000000f0000000000000000000000000000000000000000
;; 245:ccff0000ffff0000ff0000000000000000000000000000000000000000000000
;; 246:00000fff00000000000000000000000000000000000000000000000000000000
;; 247:f000000000000000000000000000000000000000000000000000000000000000
;; </SPRITES>

;; <WAVES>
;; 000:00000000ffffffff00000000ffffffff
;; 001:0123456789abcdeffedcba9876543210
;; 002:0123456789abcdef0123456789abcdef
;; 004:00223469abccddeeeeddccba96432200
;; 005:00000ffffffffff00000ffffffffffff
;; 006:5667899aa99876655667899aa9987665
;; 007:22222255555500000000000000000000
;; </WAVES>

;; <SFX>
;; 000:00400040004000700090009010c010f020f020f030f030f040f040f050f050f060f060f070f070f080f080f090f090f0a0f0a0f0b0f0b0f0c0f0c0f0204000000000
;; 001:5100410031003100410051006100710081009100a100b100c100d100e100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100b07000000000
;; 002:300750075006600560046004600280019000b000d000d000d000e000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000234000000000
;; 003:840764075406340414011400140034004400540054006400640064006400740084008400840084009400940094009400a400b400b400c400d400c400500000000000
;; 004:1507450475029501b501d501f501f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500300000000000
;; 005:030003000300030003001300130013002300230023003300330033003300330033004300430043005300630063007300730073008300830083008300104000000000
;; 006:860746036600960db608d600f600f600f600f600f600f600f600f600f600f600f600f600f600f600f600f600f600f600f600f600f600f600f600f600d44000000000
;; 007:5700470037003700470057006700770087009700a700b700c700d700e700f700f700f700f700f700f700f700f700f700f700f700f700f700f700f700307000000000
;; </SFX>

;; <PATTERNS>
;; 000:4ff1180000000000000000006991220000000000000000006991220000000000000000006991220000000000000000004ff1180000000000000000006991220000000000000000006991220000006991220000006991220000001000200000004ff1180000000000000000006991220000000000000000006991220000000000000000006991220000000000000000004ff118000000000000000000699122000000100020000000699122000000699122000000699122000000699122100020
;; 001:977136100030477136100030b77136100030477136100030add1361000307dd1360000000000000000000000000000009dd136100030477138000000a77138000000477138000000877136000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
;; 002:977136000000e77134000000977134000000e77134000000977136000000000000000000000000000000000000000000977136000000e77136000000777136000000e771360000009dd136000000bdd136100030100030000000100030000000977136000000e77136000000777136000000e771360000009dd136000000bdd136000000000000000000000000000000977136000000e77134000000977134000000e77134000000977136000000000000000000000000000000000000000000
;; 003:0000000000004000780000004ff678000000000000000000400678000000000000000000700078000000000000000000000000000000000000000000800078000000800078000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
;; 004:4ff1180000000000000000006991220000000000000000006991220000000000000000006991220000000000000000004ff1180000000000000000006991220000000000000000006991220000006991220000006991220000006991220000004ff1180000000000000000006991220000000000000000006991220000000000000000006991220000000000000000001000100000006ff1220000006ff1220000006ff1220000006ff1220000006ff1220000006ff1220000006ff122100020
;; 005:400066000000000000000000100060000000000000000000900066000000000000000000000000000000000000000000a00066000000000000000000900066000000000000000000e00066000000000000000000000000000000000000000000400066000000000000000000000000000000000000000000900066000000000000000000000000000000000000000000a00066000000000000000000900066000000000000000000a00066000000000000000000b00066000000000000e00066
;; </PATTERNS>

;; <TRACKS>
;; 000:1800001800005810001800001800001c0000500000000000000000000000000000000000000000000000000000000000000000
;; 001:400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008200
;; </TRACKS>

;; <PALETTE>
;; 000:070708332222774433cc8855993311dd7711ffdd55ffff3355aa4411552244eebb3388dd5544aa555577aabbbbffffff
;; </PALETTE>
