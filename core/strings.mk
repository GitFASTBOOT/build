
###########################################################
## Convert to lower case without requiring a shell, which isn't cacheable.
##
## $(1): string
###########################################################
to-lower=$(subst A,a,$(subst B,b,$(subst C,c,$(subst D,d,$(subst E,e,$(subst F,f,$(subst G,g,$(subst H,h,$(subst I,i,$(subst J,j,$(subst K,k,$(subst L,l,$(subst M,m,$(subst N,n,$(subst O,o,$(subst P,p,$(subst Q,q,$(subst R,r,$(subst S,s,$(subst T,t,$(subst U,u,$(subst V,v,$(subst W,w,$(subst X,x,$(subst Y,y,$(subst Z,z,$1))))))))))))))))))))))))))

###########################################################
## Convert to upper case without requiring a shell, which isn't cacheable.
##
## $(1): string
###########################################################
to-upper=$(subst a,A,$(subst b,B,$(subst c,C,$(subst d,D,$(subst e,E,$(subst f,F,$(subst g,G,$(subst h,H,$(subst i,I,$(subst j,J,$(subst k,K,$(subst l,L,$(subst m,M,$(subst n,N,$(subst o,O,$(subst p,P,$(subst q,Q,$(subst r,R,$(subst s,S,$(subst t,T,$(subst u,U,$(subst v,V,$(subst w,W,$(subst x,X,$(subst y,Y,$(subst z,Z,$1))))))))))))))))))))))))))

# Sanity-check to-lower and to-upper
lower := abcdefghijklmnopqrstuvwxyz-_
upper := ABCDEFGHIJKLMNOPQRSTUVWXYZ-_

ifneq ($(lower),$(call to-lower,$(upper)))
  $(error to-lower sanity check failure)
endif

ifneq ($(upper),$(call to-upper,$(lower)))
  $(error to-upper sanity check failure)
endif

lower :=
upper :=
