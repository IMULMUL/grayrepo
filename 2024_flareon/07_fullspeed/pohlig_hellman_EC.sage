# Sage already comes built-in with a discrete logarithm function that uses a Pohlig-Hellman / BSGS backend. 
# However, it can never hurt to implement the algorithm yourself for sake of understanding.


# The Baby-Step Giant Step (BSGS) algorithm helps reduce the complexity of calculating the discrete logarithm
# g_i^x_i mod p_i = h_i to O(sqrt(p_i)) instead of O(p_i) with traditional brute force.  The way BSGS works is that
# We rewrite the discrete logarithm x_i in terms of im + j, where m = ceil(sqrt(n)).  This allows for a meet-in-the-middle
# style calculation of $x$--namely, we first calculate g^j mod p for every 0 <= j < m, and then calculate g^i mod p for 
# 0 <= j <= p, multiplying by a^-m for every y not equal to 

def BSGS(G, PA, n, E):

    # Normally ceil(sqrt(n)) should work but for some reason some test cases break this
    M = ceil(sqrt(n)) + 1
    y = PA
    log_table = {}
    
    for j in range(M):
        log_table[j] = (j, j * G)

    inv = -M * G
    
    for i in range(M):
        for x in log_table:
            if log_table[x][1] == y:
                return i * M + log_table[x][0]
    
        y += inv
        
    return None

# The Pohlig-Hellman attack on Diffie-Hellman works as such:
# Given the generator, public keys of either Alice or Bob, as well as the multiplicative order
# Of the group (which in Diffie-Hellman is p - 1 due to prime modulus), 
# one can factor the group order (which by construction here is B-smooth) into 
# Small primes.  By Lagrange's theorem, we have that

def pohlig_hellman_EC(G, PA, E, debug=True):
    """ Attempts to use Pohlig-Hellman to compute discrete logarithm of A = g^a mod p"""
    
    # This code is pretty clunky, naive, and unoptimized at the moment, but it works.

    n = E.order() 
    factors = [p_i ^ e_i for (p_i, e_i) in factor(n)]
    crt_array = []

    if debug:
        print("[x] Factored #E(F_p) into %s" % factors)

    for p_i in factors:
        g_i = G * (n // p_i)
        h_i = PA * (n // p_i)
        x_i = BSGS(g_i, h_i, p_i, E)
        if debug and x_i != None:
            print("[x] Found discrete logarithm %d for factor %d" % (x_i, p_i))
            crt_array += [x_i]
        
        elif x_i == None:
            print("[] Did not find discrete logarithm for factor %d" % p_i)

    return crt(crt_array, factors)

def test():
    p = 0xc90102faa48f18b5eac1f76bb40a1b9fb0d841712bbe3e5576a7a56976c2baeca47809765283aa078583e1e65172a3fd
    a = 0xa079db08ea2470350c182487b50f7707dd46a58a1d160ff79297dcc9bfad6cfc96a81c4a97564118a40331fe0fc1327f
    b = 0x9f939c02a7bd7fc263a4cce416f4c575f28d0c1315c4f0c282fca6709a5f9f7f9c251c9eede9eb1baa31602167fa5380

    E = EllipticCurve(GF(p), [a, b])

    G_x = 0x087b5fe3ae6dcfb0e074b40f6208c8f6de4f4f0679d6933796d3b9bd659704fb85452f041fff14cf0e9aa7e45544f9d8
    G_y = 0x127425c1d330ed537663e87459eaa1b1b53edfe305f6a79b184b3180033aab190eb9aa003e02e9dbf6d593c5e3b08182
    G = E(G_x, G_y)

    # Define the public key point P (belongs to the binary)
    P_x = 0x195b46a760ed5a425dadcab37945867056d3e1a50124fffab78651193cea7758d4d590bed4f5f62d4a291270f1dcf499
    P_y = 0x357731edebf0745d081033a668b58aaa51fa0b4fc02cd64c7e8668a016f0ec1317fcac24d8ec9f3e75167077561e2a15
    PA = E(P_x, P_y)

    print("Attempting Pohlig-Hellman factorization with \nG = %s\nPA = %s\nE is an %s\n" 
        % (G, PA, E))
    kA = pohlig_hellman_EC(G, PA, E)
    print("[x] Recovered scalar kA such that PA = G * kA through Pohlig-Hellman: %d" % kA)
    assert kA * G == PA
    print("[x] Confirmed scalar kA such that PA = G * kA through Pohlig-Hellman: %d" % kA)

if __name__ == "__main__":
    test()