library(openxlsx)
library(tidyverse)


inhousechars <- c("5", "O", "8", "o", "2", "Er", "1r", "Ur", "C", "T", "D", "G", "i", "3r", "a", "c", "u", "U", "1", "@", "E", "e", "^", "b", "d", "f", "g", "h", "j", "k", "l", "m", "n", "N", "p", "r", "s", "S", "t", "v", "w", "z", "Z")
ipachars <- c("aɪ", "aʊ", "eɪ", "oʊ", "ɔɪ", "ɛɹ", "ɪɹ", "ʊɹ", "tʃ", "θ", "ð", "dʒ", "i", "ɚ", "ɑ", "ɔ", "u", "ʊ", "ɪ", "æ", "ɛ", "ə", "ʌ", "b", "d", "f", "g", "h", "j", "k", "l", "m", "n", "ŋ", "p", "ɹ", "s", "ʃ", "t", "v", "w", "z", "ʒ")

inhouse_to_ipa <- function(word) {
  output <- ""
  
  i <- 1
  while (i <= nchar(word)) {
    matched <- FALSE
    
    for (j in 1:length(inhousechars)) {
      inhousekey <- inhousechars[j]
      ipakey <- ipachars[j]
      
      if (substr(word, i, i + nchar(inhousekey) - 1) == inhousekey) {
        output <- paste0(output, ipakey)
        i <- i + nchar(inhousekey)
        matched <- TRUE
        break
      }
    }
    
    if (!matched) {
      output <- paste0(output, substr(word, i, i))
      i <- i + 1
    }
  }
  
  return(output)
}

ipa_to_inhouse <- function(word) {
  output <- ""
  
  i <- 1
  while (i <= nchar(word)) {
    matched <- FALSE
    
    for (j in 1:length(ipachars)) {
      ipakey <- ipachars[j]
      inhousekey <- inhousechars[j]
      
      if (substr(word, i, i + nchar(ipakey) - 1) == ipakey) {
        output <- paste0(output, inhousekey)
        i <- i + nchar(ipakey)
        matched <- TRUE
        break
      }
    }
    
    if (!matched) {
      output <- paste0(output, substr(word, i, i))
      i <- i + 1
    }
  }
  
  return(output)
}



#example:
#inhouseData <- read.xlsx("Word Attack template.xlsx")
#inhouseData <- inhouseData %>% rowwise() %>% mutate(ipa = inhouse_to_ipa(inhouse))
