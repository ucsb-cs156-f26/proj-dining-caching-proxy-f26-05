package edu.ucsb.cs156.diningcachingproxy.collections;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

/**
 * A MongoDB document holding the cached response for a single upstream UCSB API request, keyed by
 * the resolved request path (no query parameters are used by any of the endpoints this proxy
 * currently serves).
 */
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
@Document(collection = "cached_responses")
public class CachedResponse {

  @Id private String id;

  @Indexed(unique = true)
  private String requestPath;

  private int responseStatus;
  private String responseBody;

  // Times this request path has been served (1 on first cache, incremented on every
  // subsequent cache hit) — feeds the admin endpoint-inventory view (issue #2).
  private long hitCount;

  // Times a request for this path had to be fetched from the upstream UCSB API (a cache miss).
  // Set to 1 when the path is first fetched and cached. Cached entries currently never expire, so
  // this only grows past 1 once entries can be removed or refreshed. Entries cached before this
  // field existed read back as 0.
  private long missCount;
}
