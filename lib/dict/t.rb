abc="abc-defx'ijka\"aa cc"
printf("%s\n",abc)
printf("[%s]\n",abc.gsub(/['\-\"]/," "))
