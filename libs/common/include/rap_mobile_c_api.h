#ifndef RAP_MOBILE_C_API_H
#define RAP_MOBILE_C_API_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#if defined(_WIN32)
#define RAP_EXPORT __declspec(dllexport)
#else
#define RAP_EXPORT __attribute__((visibility("default")))
#endif

typedef struct {
    uint32_t payload_type;
    uint64_t sequence_num;
    uint64_t timestamp_ms;
    const uint8_t* payload_data;
    size_t payload_size;
} rap_c_packet_t;

RAP_EXPORT int32_t rap_mobile_init(void);

RAP_EXPORT int32_t rap_mobile_get_p2p_id(char* out_buf, size_t buf_len);

RAP_EXPORT int32_t rap_mobile_encode_packet(uint32_t payload_type,
                                            uint64_t sequence_num,
                                            uint64_t timestamp_ms,
                                            const uint8_t* payload_data,
                                            size_t payload_len,
                                            uint8_t* out_buf,
                                            size_t max_out_len,
                                            size_t* written_len);

RAP_EXPORT int32_t rap_mobile_decode_packet(const uint8_t* in_buf,
                                            size_t in_len,
                                            rap_c_packet_t* out_packet);

RAP_EXPORT void rap_mobile_free_packet(rap_c_packet_t* packet);

#ifdef __cplusplus
}
#endif

#endif // RAP_MOBILE_C_API_H
