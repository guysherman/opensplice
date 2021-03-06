/*
 *                         OpenSplice DDS
 *
 *   This software and documentation are Copyright 2006 to 2011 PrismTech
 *   Limited and its licensees. All rights reserved. See file:
 *
 *                     $OSPL_HOME/LICENSE 
 *
 *   for full copyright notice and license terms. 
 *
 */

package DDS;


public interface TypeSupportOperations 
{
    int
    register_type(
        DDS.DomainParticipant domain,
        String type_name);
    String
    get_type_name();

} // interface TypeSupportOperations
