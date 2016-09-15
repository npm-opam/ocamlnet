/* From RFC 1833 */

const PMAP_PORT = 111;      /* portmapper port number */

struct mapping {
    unsigned int prog;
    unsigned int vers;
    unsigned _unboxed int prot;
    unsigned _unboxed int port;
};

const IPPROTO_TCP = 6;      /* protocol number for TCP/IP */
const IPPROTO_UDP = 17;     /* protocol number for UDP/IP */

struct pmaplist {
    mapping map;
    pmaplist *next;
};

typedef pmaplist * pmaplist_p;

struct call_args {
    unsigned int call_prog;
    unsigned int call_vers;
    unsigned int call_proc;
    opaque call_args<>;
};

struct call_result {
    unsigned _unboxed int call_port;
    opaque call_res<>;
};

/* RPCBIND, RFC 1833 */

/*
 * rpcbind address for TCP/UDP
 */
const RPCB_PORT = 111;

typedef string uaddr<>;
/* Universal address, see RFC 5665 */


/*
 * A mapping of (program, version, network ID) to address
 *
 * The network identifier  (r_netid):
 * This is a string that represents a local identification for a
 * network. This is defined by a system administrator based on local
 * conventions, and cannot be depended on to have the same value on
 * every system.
 */
struct rpcb {
    unsigned int r_prog;    /* program number */
    unsigned int r_vers;    /* version number */
    string r_netid<>;        /* network id */
    uaddr  r_addr;         /* universal address */
    string r_owner<>;        /* owner of this service */
};

struct rp__list {
    rpcb rpcb_map;
    struct rp__list *rpcb_next;
};

typedef rp__list *rpcblist_ptr;        /* results of RPCBPROC_DUMP */


/*
 * Arguments of remote calls
 */
typedef call_args rpcb_rmtcallargs;

/*
 * Results of the remote call
 */
struct rpcb_rmtcallres {
    uaddr call_addr;            /* remote universal address */
    opaque call_res2<>;         /* result */
};


/*
 * rpcb_entry contains a merged address of a service on a particular
 * transport, plus associated netconfig information.  A list of
 * rpcb_entry items is returned by RPCBPROC_GETADDRLIST.  The meanings
 * and values used for the r_nc_* fields are given below.
 *
 * The network identifier  (r_nc_netid):

 *   This is a string that represents a local identification for a
 *   network.  This is defined by a system administrator based on
 *   local conventions, and cannot be depended on to have the same
 *   value on every system.
 */
/* GPS: There is now a IANA registry for NetID's. See RFC 5665.
   Common names are "tcp", "tcp6", "udp", "udp6"
*/
/*
 *
 * Transport semantics (r_nc_semantics):
 *  This represents the type of transport, and has the following values:
 *     NC_TPI_CLTS     (1)      Connectionless
 *     NC_TPI_COTS     (2)      Connection oriented
 *     NC_TPI_COTS_ORD (3)      Connection oriented with graceful close
 *     NC_TPI_RAW      (4)      Raw transport
 *
 * Protocol family (r_nc_protofmly):
 *   This identifies the family to which the protocol belongs.  The
 *   following values are defined:
 *     NC_NOPROTOFMLY   "-"
 *     NC_LOOPBACK      "loopback"
 *     NC_INET          "inet"
 *     NC_IMPLINK       "implink"
 *     NC_PUP           "pup"
 *     NC_CHAOS         "chaos"
 *     NC_NS            "ns"
 *     NC_NBS           "nbs"
 *     NC_ECMA          "ecma"
 *     NC_DATAKIT       "datakit"
 *     NC_CCITT         "ccitt"
 *     NC_SNA           "sna"
 *     NC_DECNET        "decnet"
 *     NC_DLI           "dli"
 *     NC_LAT           "lat"
 *     NC_HYLINK        "hylink"
 *     NC_APPLETALK     "appletalk"
 *     NC_NIT           "nit"
 *     NC_IEEE802       "ieee802"
 *     NC_OSI           "osi"
 *     NC_X25           "x25"
 *     NC_OSINET        "osinet"
 *     NC_GOSIP         "gosip"
 *
 * Protocol name (r_nc_proto):
 *   This identifies a protocol within a family.  The following are
 *   currently defined:
 *      NC_NOPROTO      "-"
 *      NC_TCP          "tcp"
 *      NC_UDP          "udp"
 *      NC_ICMP         "icmp"
 */
struct rpcb_entry {
    string          r_maddr<>;            /* merged address of service */
    string          r_nc_netid<>;         /* netid field */
    unsigned _unboxed int r_nc_semantics; /* semantics of transport */
    string          r_nc_protofmly<>;     /* protocol family */
    string          r_nc_proto<>;         /* protocol name */
};

/*
 * A list of addresses supported by a service.
 */
struct rpcb_entry_list {
    rpcb_entry rpcb_entry_map;
    struct rpcb_entry_list *rpcb_entry_next;
};

typedef rpcb_entry_list *rpcb_entry_list_ptr;
/*
 * rpcbind statistics
 */

/*
const rpcb_highproc_2 = RPCBPROC_CALLIT;
const rpcb_highproc_3 = RPCBPROC_TADDR2UADDR;
const rpcb_highproc_4 = RPCBPROC_GETSTAT;
*/

const RPCBSTAT_HIGHPROC = 13; /* # of procs in rpcbind V4 plus one */
const RPCBVERS_STAT     = 3; /* provide only for rpcbind V2, V3 and V4 */
const RPCBVERS_4_STAT   = 2;
const RPCBVERS_3_STAT   = 1;
const RPCBVERS_2_STAT   = 0;

/* Link list of all the stats about getport and getaddr */
struct rpcbs_addrlist _prefix "al_" {
    unsigned int prog;
    unsigned int vers;
    _int32 int success;
    _int32 int failure;
    string netid<>;
    struct rpcbs_addrlist *next;
};

/* Link list of all the stats about rmtcall */
struct rpcbs_rmtcalllist _prefix "cl_" {
    unsigned int prog;
    unsigned int vers;
    unsigned int proc;
    _int32 int success;
    _int32 int failure;
    _int32 int indirect;    /* whether callit or indirect */
    string netid<>;
    struct rpcbs_rmtcalllist *next;
};

typedef int rpcbs_proc[RPCBSTAT_HIGHPROC];
typedef rpcbs_addrlist *rpcbs_addrlist_ptr;
typedef rpcbs_rmtcalllist *rpcbs_rmtcalllist_ptr;

struct rpcb_stat {
    rpcbs_proc              info;
    _int32 int              setinfo;
    _int32 int              unsetinfo;
    rpcbs_addrlist_ptr      addrinfo;
    rpcbs_rmtcalllist_ptr   rmtinfo;
};
/*
 * One rpcb_stat structure is returned for each version of rpcbind
 * being monitored.
 */

typedef rpcb_stat rpcb_stat_byvers[RPCBVERS_STAT];

/*
 * netbuf structure, used to store the transport specific form of
 * a universal transport address.
 */
struct netbuf {
    unsigned int maxlen;
    opaque buf<>;
};


/*
 * rpcbind procedures
 */
program PMAP {
    version V2 {
        void
            PMAPPROC_NULL(void)         = 0;

        bool
            PMAPPROC_SET(mapping)       = 1;

        bool
            PMAPPROC_UNSET(mapping)     = 2;

        unsigned _unboxed int
            PMAPPROC_GETPORT(mapping)   = 3;

        pmaplist_p
            PMAPPROC_DUMP(void)         = 4;

        call_result
            PMAPPROC_CALLIT(call_args)  = 5;
    } = 2;

    version V3 {
        void
            RPCBPROC_NULL(void) = 0;

        bool
            RPCBPROC_SET(rpcb) = 1;

        bool
            RPCBPROC_UNSET(rpcb) = 2;

        uaddr
            RPCBPROC_GETADDR(rpcb) = 3;

        rpcblist_ptr
            RPCBPROC_DUMP(void) = 4;

        rpcb_rmtcallres
            RPCBPROC_CALLIT(rpcb_rmtcallargs) = 5;

        unsigned int
            RPCBPROC_GETTIME(void) = 6;

        netbuf
            RPCBPROC_UADDR2TADDR(uaddr) = 7;

        uaddr
            RPCBPROC_TADDR2UADDR(netbuf) = 8;
    } = 3;

    version V4 {
        void
            RPCBPROC_NULL(void) = 0;

        bool
            RPCBPROC_SET(rpcb) = 1;
        
        bool
            RPCBPROC_UNSET(rpcb) = 2;
        
        uaddr
            RPCBPROC_GETADDR(rpcb) = 3;
        
        rpcblist_ptr
            RPCBPROC_DUMP(void) = 4;
        
     /*
      * NOTE: RPCBPROC_BCAST has the same functionality as CALLIT;
      * the new name is intended to indicate that this
      * procedure should be used for broadcast RPC, and
      * RPCBPROC_INDIRECT should be used for indirect calls.
      */
        rpcb_rmtcallres
            RPCBPROC_BCAST(rpcb_rmtcallargs) = 5;

        unsigned int
            RPCBPROC_GETTIME(void) = 6;

        netbuf
            RPCBPROC_UADDR2TADDR(uaddr) = 7;

        uaddr
            RPCBPROC_TADDR2UADDR(netbuf) = 8;

        uaddr
            RPCBPROC_GETVERSADDR(rpcb) = 9;
        
        rpcb_rmtcallres
            RPCBPROC_INDIRECT(rpcb_rmtcallargs) = 10;
        
        rpcb_entry_list_ptr
            RPCBPROC_GETADDRLIST(rpcb) = 11;

        rpcb_stat_byvers
            RPCBPROC_GETSTAT(void) = 12;
    } = 4;
} = 100000;
