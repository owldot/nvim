; extends

; @conditional
(if
  consequence: (then) @conditional.inner) @conditional.outer

(if
  alternative: (else) @conditional.inner)

(elsif
  consequence: (then) @conditional.inner) @conditional.outer

(unless
  consequence: (then) @conditional.inner) @conditional.outer
